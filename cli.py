"""
Command Line Interface (CLI) for C2PA Audio Provenance System (Wave 2 Enterprise Edition).

Exit Codes:
  0 = Success
  1 = General / Argument Error
 10 = Signature verification failed
 11 = Content ID / file hash verification failed
 12 = Schema validation failed
 20 = Migration not possible
 21 = Validation failed post-migration
"""

import sys
import os
import json
import argparse
import shutil
import time
from typing import Optional

from core.manifest import create_manifest
from core.canonical_audio import embed_c2pa_riff_chunk, extract_c2pa_riff_chunk, decode_canonical_audio
from core.watermark import embed_audio_watermark, extract_audio_watermark
from core.ipfs import create_ipfs_anchor
from core.spatial_audio import build_spatial_descriptor
from core.wavelet import compute_wavelet_hash, compare_wavelet_hashes
from core.daw_plugin_bridge import DAWExportWatcher
from audit.demo_ledger import DemoTransparencyLedger, verify_inclusion_proof
from audit.decentralized_storage import DecentralizedStorageAdaptor
from audit.webhook_dispatcher import WebHookDispatcher
from security.keys import generate_keypair, save_keypair, load_private_key, load_public_key, get_key_id, get_public_key_string, generate_x509_certificate
from security.verifier import verify_manifest_signature, verify_manifest_against_audio
from security.pow import solve_pow, verify_pow
from security.zkp import redact_manifest_metadata
from security.threshold_sig import generate_threshold_shares, sign_partial_share, aggregate_threshold_signatures
from reporting.json_schema import validate_manifest
from reporting.pdf_report import generate_pdf_report
from core.migration import migrate_manifest, MigrationError
from core.acoustid import get_fpcalc_version
from audit.audit_log import AuditLogger

DEFAULT_KEY_DIR = os.path.expanduser("~/.audio_provenance/keys")
DEFAULT_PRIV_KEY_PATH = os.path.join(DEFAULT_KEY_DIR, "ed25519_priv.pem")
DEFAULT_PUB_KEY_PATH = os.path.join(DEFAULT_KEY_DIR, "ed25519_pub.pem")

def ensure_default_keys() -> str:
    """Ensures default Ed25519 keypair exists in user directory."""
    if not os.path.exists(DEFAULT_PRIV_KEY_PATH):
        priv_key, pub_key = generate_keypair()
        save_keypair(priv_key, DEFAULT_PRIV_KEY_PATH, DEFAULT_PUB_KEY_PATH)
    return DEFAULT_PRIV_KEY_PATH

def cmd_create(args) -> int:
    logger = AuditLogger()
    try:
        key_path = args.key or ensure_default_keys()
        private_key = load_private_key(key_path)

        software_chain = [s.strip() for s in args.software.split(",")] if args.software else None

        manifest = create_manifest(
            audio_path=args.input,
            private_key=private_key,
            creator=args.creator,
            client=args.client,
            project=args.project,
            software_chain=software_chain,
            enable_tsa=args.tsa
        )

        output_json = args.output
        if not output_json:
            base, _ = os.path.splitext(args.input)
            output_json = f"{base}.manifest.json"

        os.makedirs(os.path.dirname(os.path.abspath(output_json)), exist_ok=True)
        with open(output_json, "w", encoding="utf-8") as f:
            json.dump(manifest, f, indent=2, ensure_ascii=False)

        print(f"Manifest created successfully: {output_json}")
        logger.log_event("CREATE_MANIFEST", {"input": args.input, "output": output_json, "manifest_id": manifest["manifest_id"]})

        # Demo Transparency Ledger logging
        ledger = DemoTransparencyLedger()
        rec = ledger.append_manifest(manifest["manifest_id"], manifest)
        print(f"Logged to Demo Transparency Ledger (Rekor Compatible) - Index: {rec['logIndex']}, Merkle Root: {rec['rootHash']}")

        # IPFS CID Anchor
        ipfs_anchor = create_ipfs_anchor(manifest)
        print(f"IPFS CIDv1 URN: {ipfs_anchor['manifest_urn']}")

        # Watermarking
        if args.watermark:
            import wave
            audio_res = decode_canonical_audio(args.input)
            wm_pcm = embed_audio_watermark(audio_res.pcm_bytes, manifest["manifest_id"], audio_res.bit_depth)
            wm_audio_path = f"{os.path.splitext(args.input)[0]}.watermarked.wav"
            with wave.open(wm_audio_path, "wb") as wf:
                wf.setnchannels(audio_res.channels)
                wf.setsampwidth(audio_res.bit_depth // 8)
                wf.setframerate(audio_res.sample_rate)
                wf.writeframes(wm_pcm)
            print(f"In-band audio watermark embedded into PCM samples: {wm_audio_path}")

        # Embedded RIFF c2pa chunk
        if args.embed_c2pa:
            manifest_bytes = json.dumps(manifest).encode("utf-8")
            embedded_wav_path = f"{os.path.splitext(args.input)[0]}.c2pa.wav"
            embed_c2pa_riff_chunk(args.input, manifest_bytes, embedded_wav_path)
            print(f"Embedded signed c2pa RIFF chunk into WAV: {embedded_wav_path}")

        if args.pdf:
            generate_pdf_report(manifest, args.pdf)
            print(f"PDF report generated: {args.pdf}")
            logger.log_event("GENERATE_PDF", {"output": args.pdf, "manifest_id": manifest["manifest_id"]})

        # Studio Webhook Dispatcher
        if getattr(args, "webhook", None):
            secret_bytes = args.webhook_secret.encode("utf-8") if getattr(args, "webhook_secret", None) else b"lysen-default-secret"
            dispatcher = WebHookDispatcher(secret_bytes)
            dispatcher.dispatch_event("MANIFEST_CREATED", {"manifest_id": manifest["manifest_id"], "audio": args.input}, args.webhook)
            print(f"[WebHook] Dispatched MANIFEST_CREATED event to {args.webhook} (HMAC-SHA256 signed)")

        return 0
    except ValueError as ve:
        print(f"Schema / Validation Error: {ve}", file=sys.stderr)
        return 12
    except Exception as e:
        print(f"Error creating manifest: {e}", file=sys.stderr)
        return 1

def cmd_verify(args) -> int:
    logger = AuditLogger()
    try:
        manifest_dict = None

        if args.extract_c2pa:
            c2pa_bytes = extract_c2pa_riff_chunk(args.extract_c2pa)
            if not c2pa_bytes:
                print(f"No embedded c2pa chunk found in WAV: {args.extract_c2pa}", file=sys.stderr)
                return 1
            manifest_dict = json.loads(c2pa_bytes.decode("utf-8"))
            args.audio = args.extract_c2pa
        elif args.manifest:
            if not os.path.exists(args.manifest):
                print(f"Manifest file not found: {args.manifest}", file=sys.stderr)
                return 1

            with open(args.manifest, "r", encoding="utf-8") as f:
                manifest_dict = json.load(f)

        if not manifest_dict:
            print("Must specify --manifest or --extract-c2pa", file=sys.stderr)
            return 1

        valid_schema, schema_err = validate_manifest(manifest_dict)
        if not valid_schema:
            print(f"Manifest schema validation failed: {schema_err}", file=sys.stderr)
            return 12

        pub_key_override = load_public_key(args.public_key) if args.public_key else None

        if args.audio:
            res = verify_manifest_against_audio(manifest_dict, args.audio, pub_key_override)
            if not res.signature_valid:
                print("FAILED: Signature verification failed.", file=sys.stderr)
                for err in res.errors:
                    print(f"  - {err}", file=sys.stderr)
                logger.log_event("VERIFY_MANIFEST", {"audio": args.audio, "result": "SIGNATURE_INVALID"}, status="FAILED")
                return 10

            if args.extract_c2pa:
                if not res.content_id_match:
                    print("FAILED: Embedded audio PCM content integrity check failed.", file=sys.stderr)
                    for err in res.errors:
                        print(f"  - {err}", file=sys.stderr)
                    logger.log_event("VERIFY_MANIFEST", {"audio": args.audio, "result": "INTEGRITY_MISMATCH"}, status="FAILED")
                    return 11

                print("VERIFICATION SUCCESSFUL (Embedded C2PA WAV)")
                print(f"  - Signature: VALID")
                print(f"  - Content ID Match (PCM exact): {res.content_id_match}")
                print(f"  - Container File Hash: Embedded c2pa chunk verified in RIFF header")
                logger.log_event("VERIFY_MANIFEST", {"audio": args.audio, "result": "SUCCESS", "mode": "embedded_c2pa"})
                return 0
            else:
                if res.content_id_match and res.file_hash_match:
                    print("VERIFICATION SUCCESSFUL (Pristine Bit-Exact Master)")
                    print(f"  - Signature: VALID")
                    print(f"  - Content ID Match: {res.content_id_match}")
                    print(f"  - File Hash Match: {res.file_hash_match}")
                    print(f"  - Acoustic Match: {res.acoustic_match}")
                    logger.log_event("VERIFY_MANIFEST", {"audio": args.audio, "result": "SUCCESS", "tier": "bit_exact"})
                    return 0
                elif (getattr(args, "perceptual", False) or getattr(args, "allow_lossy", False)) and res.acoustic_match:
                    print("VERIFICATION SUCCESSFUL (Perceptual Lineage Match)")
                    print(f"  - Signature: VALID")
                    print(f"  - Content ID Match: False (Transcoded or compressed derivative)")
                    print(f"  - Acoustic Match: True (Perceptually authentic via Chromaprint)")
                    print(f"  - Lineage Verdict: AUTHENTIC_DERIVATIVE")
                    logger.log_event("VERIFY_MANIFEST", {"audio": args.audio, "result": "SUCCESS", "tier": "perceptual"})
                    return 0
                else:
                    print("FAILED: Audio content integrity check failed.", file=sys.stderr)
                    for err in res.errors:
                        print(f"  - {err}", file=sys.stderr)
                    logger.log_event("VERIFY_MANIFEST", {"audio": args.audio, "result": "INTEGRITY_MISMATCH"}, status="FAILED")
                    return 11
        else:
            sig_valid, sig_err = verify_manifest_signature(manifest_dict, pub_key_override)
            if not sig_valid:
                print(f"FAILED: Signature verification failed: {sig_err}", file=sys.stderr)
                logger.log_event("VERIFY_MANIFEST", {"result": "SIGNATURE_INVALID"}, status="FAILED")
                return 10

            print("VERIFICATION SUCCESSFUL: Manifest signature is valid.")
            logger.log_event("VERIFY_MANIFEST", {"result": "SUCCESS"})
            return 0
    except Exception as e:
        print(f"Verification error: {e}", file=sys.stderr)
        return 1

def cmd_report(args) -> int:
    try:
        with open(args.manifest, "r", encoding="utf-8") as f:
            manifest_dict = json.load(f)

        generate_pdf_report(manifest_dict, args.output)
        print(f"PDF report generated successfully: {args.output}")
        return 0
    except Exception as e:
        print(f"Failed to generate report: {e}", file=sys.stderr)
        return 1

def cmd_migrate(args) -> int:
    logger = AuditLogger()
    try:
        if not os.path.exists(args.input):
            print(f"Input manifest not found: {args.input}", file=sys.stderr)
            return 1

        with open(args.input, "r", encoding="utf-8") as f:
            manifest_dict = json.load(f)

        if args.backup:
            backup_path = f"{args.input}.bak"
            shutil.copyfile(args.input, backup_path)
            print(f"Backup saved to {backup_path}")

        try:
            migrated = migrate_manifest(manifest_dict, args.to)
        except MigrationError as me:
            print(f"Migration impossible: {me}", file=sys.stderr)
            logger.log_event("MIGRATE_MANIFEST", {"input": args.input, "target": args.to, "error": str(me)}, status="FAILED")
            return me.exit_code

        if args.validate:
            valid, err = validate_manifest(migrated)
            if not valid:
                print(f"Post-migration validation failed: {err}", file=sys.stderr)
                logger.log_event("MIGRATE_MANIFEST", {"input": args.input, "target": args.to, "error": err}, status="VALIDATION_FAILED")
                return 21

        with open(args.input, "w", encoding="utf-8") as f:
            json.dump(migrated, f, indent=2, ensure_ascii=False)

        print(f"Manifest migrated successfully to version {args.to}")
        logger.log_event("MIGRATE_MANIFEST", {"input": args.input, "target": args.to, "status": "SUCCESS"})
        return 0
    except Exception as e:
        print(f"Migration error: {e}", file=sys.stderr)
        return 1

def cmd_keys_generate(args) -> int:
    try:
        out_dir = args.output_dir or DEFAULT_KEY_DIR
        priv_path = os.path.join(out_dir, "ed25519_priv.pem")
        pub_path = os.path.join(out_dir, "ed25519_pub.pem")
        cert_path = os.path.join(out_dir, "x509_cert.pem")

        priv_key, pub_key = generate_keypair()
        save_keypair(priv_key, priv_path, pub_path)

        x509_pem = generate_x509_certificate(priv_key)
        with open(cert_path, "w", encoding="utf-8") as f:
            f.write(x509_pem)

        key_id = get_key_id(pub_key)
        pub_str = get_public_key_string(pub_key)

        print(f"Generated new Ed25519 keypair & X.509 Certificate:")
        print(f"  Private Key: {priv_path}")
        print(f"  Public Key:  {pub_path}")
        print(f"  X.509 Cert:  {cert_path}")
        print(f"  Key ID:      {key_id}")
        print(f"  Public Str:  {pub_str}")
        return 0
    except Exception as e:
        print(f"Error generating keys: {e}", file=sys.stderr)
        return 1

def cmd_ledger(args) -> int:
    ledger = DemoTransparencyLedger()
    if args.action == "root":
        r = ledger.compute_merkle_root()
        print(f"Demo Transparency Ledger Merkle Root: sha256:{r}")
        print(f"Total Entries: {len(ledger.entries)}")
        return 0
    elif args.action == "proof":
        p = ledger.get_inclusion_proof(args.index)
        print(f"Inclusion Proof for Entry {args.index}:")
        print(json.dumps(p, indent=2))
        return 0
    return 1

def cmd_spatial(args) -> int:
    res = build_spatial_descriptor(args.bit_depth, args.sample_rate, args.channels)
    print(f"Spatial Descriptor: {res['canonical_descriptor']}")
    print(f"Format: {res['spatial_format']}, Map: {res['channel_map']}")
    return 0

def cmd_wavelet(args) -> int:
    audio_res = decode_canonical_audio(args.input)
    wh = compute_wavelet_hash(audio_res.pcm_bytes, audio_res.bit_depth)
    print(f"DWT Wavelet Hash: {wh}")
    return 0

def cmd_info(args) -> int:
    print("=== Lysen Audio Provenance System Info ===")
    print(f"Python Version:    {sys.version.split()[0]}")
    print(f"fpcalc Version:    {get_fpcalc_version()}")
    
    try:
        import blake3
        b3_status = "Available (native mmap streaming)"
    except ImportError:
        b3_status = "Unavailable (hashlib fallback)"
    print(f"BLAKE3 Support:    {b3_status}")

    logger = AuditLogger()
    entries = logger.get_recent_entries(5)
    print(f"\nRecent Audit Log Entries ({len(entries)}):")
    for entry in entries:
        print(f"  [{entry.get('timestamp')}] {entry.get('action')} - {entry.get('status')}")
    return 0

def cmd_watch(args) -> int:
    logger = AuditLogger()
    key_path = args.key or ensure_default_keys()
    private_key = load_private_key(key_path)

    print(f"=== Lysen DAW Export Watcher Daemon ===")
    print(f"Monitoring Directory: {os.path.abspath(args.dir)}")
    print(f"Target DAW Profile:   {args.daw}")
    print(f"Auto-Sign Enabled:    {args.auto_sign}")

    watcher = DAWExportWatcher(args.dir, daw_name=args.daw, auto_sign=args.auto_sign)

    def on_export(fpath: str, meta: dict):
        base, _ = os.path.splitext(fpath)
        out_manifest = f"{base}.manifest.json"
        manifest = create_manifest(
            audio_path=fpath,
            private_key=private_key,
            creator=args.creator or "DAW Auto-Signer",
            client=meta.get("daw", args.daw),
            project=args.project or os.path.basename(fpath),
            software_chain=[meta.get("render_engine", "Lysen DAW Bridge")]
        )
        with open(out_manifest, "w", encoding="utf-8") as f:
            json.dump(manifest, f, indent=2, ensure_ascii=False)
        print(f"[DAW Watcher] Auto-signed: {os.path.basename(fpath)} -> {os.path.basename(out_manifest)}")
        logger.log_event("DAW_AUTO_SIGN", {"file": fpath, "manifest": out_manifest, "daw": meta.get("daw")})

    if getattr(args, "once", False):
        if os.path.exists(args.dir):
            for fname in os.listdir(args.dir):
                if fname.endswith((".wav", ".flac", ".aiff")) and not fname.endswith(".c2pa.json"):
                    fp = os.path.join(args.dir, fname)
                    if watcher._is_file_settled(fp):
                        m = watcher._build_daw_metadata(fp)
                        on_export(fp, m)
        print("Single scan complete.")
        return 0

    print("Press Ctrl+C to terminate.")
    watcher.start_watching(callback=on_export)
    try:
        while True:
            time.sleep(0.5)
    except KeyboardInterrupt:
        watcher.stop_watching()
        print("\nDAW Watcher stopped.")
    return 0

def cmd_permaweb(args) -> int:
    try:
        if not os.path.exists(args.manifest):
            print(f"Manifest file not found: {args.manifest}", file=sys.stderr)
            return 1
        with open(args.manifest, "r", encoding="utf-8") as f:
            manifest_dict = json.load(f)

        adaptor = DecentralizedStorageAdaptor(
            ipfs_gateway=args.ipfs_gateway,
            arweave_gateway=args.arweave_gateway
        )
        res = adaptor.publish_manifest_to_permaweb(manifest_dict)
        print("=== Permaweb Decentralized Storage Anchor ===")
        print(f"Status:          {res['status']}")
        print(f"IPFS CIDv1:      {res['ipfs']['cid']}")
        print(f"IPFS URI:        {res['ipfs']['uri']}")
        print(f"IPFS Gateway:    {res['ipfs']['gateway_url']}")
        print(f"Arweave TXID:    {res['arweave']['txid']}")
        print(f"Arweave URI:     {res['arweave']['uri']}")
        print(f"Permaweb URL:    {res['arweave']['permaweb_url']}")
        print(f"Payload Size:    {res['size_bytes']} bytes")
        return 0
    except Exception as e:
        print(f"Permaweb publishing error: {e}", file=sys.stderr)
        return 1

def cmd_serve(args) -> int:
    try:
        from server.api import run_server
        run_server(host=args.host, port=args.port)
        return 0
    except Exception as e:
        print(f"Server error: {e}", file=sys.stderr)
        return 1

def main():
    parser = argparse.ArgumentParser(prog="lysen", description="Lysen: C2PA Audio Provenance & Cryptographic Authenticity System")
    subparsers = parser.add_subparsers(dest="command", help="Sub-commands")

    # Create command
    p_create = subparsers.add_parser("create", help="Create signed provenance manifest for WAV audio")
    p_create.add_argument("--input", "-i", required=True, help="Input WAV audio file")
    p_create.add_argument("--key", "-k", help="Path to Ed25519 private key PEM file")
    p_create.add_argument("--output", "-o", help="Output manifest JSON path")
    p_create.add_argument("--pdf", help="Optional output path for PDF report")
    p_create.add_argument("--creator", default="Jane Producer", help="Creator name")
    p_create.add_argument("--client", default="Studio XYZ", help="Client name")
    p_create.add_argument("--project", default="Album Project", help="Project name")
    p_create.add_argument("--software", help="Comma-separated software chain")
    p_create.add_argument("--tsa", action="store_true", default=True, help="Embed RFC 3161 TSA timestamp")
    p_create.add_argument("--watermark", action="store_true", help="Embed in-band LSB audio watermark")
    p_create.add_argument("--embed-c2pa", action="store_true", help="Embed signed c2pa RIFF chunk into WAV file")
    p_create.add_argument("--webhook", help="Optional webhook URL to dispatch signed event")
    p_create.add_argument("--webhook-secret", default="lysen-default-secret", help="Secret key for webhook HMAC-SHA256 signature")

    # Verify command
    p_verify = subparsers.add_parser("verify", help="Verify signed manifest & optional audio file")
    p_verify.add_argument("--manifest", "-m", help="Manifest JSON file path")
    p_verify.add_argument("--audio", "-a", help="Optional audio file path to verify content identity")
    p_verify.add_argument("--extract-c2pa", help="WAV file to extract and verify embedded c2pa chunk from")
    p_verify.add_argument("--public-key", "-p", help="Optional public key PEM or string override")
    p_verify.add_argument("--perceptual", "--allow-lossy", action="store_true", help="Allow lossy transcodes if acoustic perceptual fingerprint matches")

    # Report command
    p_report = subparsers.add_parser("report", help="Generate PDF provenance report from manifest")
    p_report.add_argument("--manifest", "-m", required=True, help="Manifest JSON file path")
    p_report.add_argument("--output", "-o", required=True, help="Output PDF report path")

    # Migrate command
    p_migrate = subparsers.add_parser("migrate", help="Migrate manifest schema version")
    p_migrate.add_argument("--input", "-i", required=True, help="Manifest JSON file path")
    p_migrate.add_argument("--to", required=True, help="Target schema version (e.g., 1.1.0)")
    p_migrate.add_argument("--validate", action="store_true", help="Validate post-migration")
    p_migrate.add_argument("--backup", action="store_true", help="Create backup of input file")

    # Keys command
    p_keys = subparsers.add_parser("keys", help="Key management commands")
    keys_sub = p_keys.add_subparsers(dest="keys_command")
    p_gen = keys_sub.add_parser("generate", help="Generate Ed25519 keypair and X.509 certificate")
    p_gen.add_argument("--output-dir", "-o", help="Directory to save keys")

    # Ledger command
    p_ledger = subparsers.add_parser("ledger", help="Demo Transparency Ledger commands")
    p_ledger.add_argument("action", choices=["root", "proof"])
    p_ledger.add_argument("--index", type=int, default=0, help="Log entry index for inclusion proof")

    # Spatial command
    p_spatial = subparsers.add_parser("spatial", help="3D Spatial Audio Descriptor helper")
    p_spatial.add_argument("--channels", type=int, default=12)
    p_spatial.add_argument("--sample-rate", type=int, default=48000)
    p_spatial.add_argument("--bit-depth", type=int, default=24)

    # Wavelet command
    p_wavelet = subparsers.add_parser("wavelet", help="Compute DWT wavelet invariant hash")
    p_wavelet.add_argument("--input", "-i", required=True, help="Input WAV audio file")

    # Watch command (DAW Watcher)
    p_watch = subparsers.add_parser("watch", help="Watch DAW export directory and auto-sign renders")
    p_watch.add_argument("--dir", "-d", required=True, help="Directory to monitor for audio exports")
    p_watch.add_argument("--daw", default="ProTools", choices=["ProTools", "Ableton Live", "Logic Pro", "FL Studio", "Cubase", "Reaper"], help="Target DAW profile")
    p_watch.add_argument("--key", "-k", help="Path to Ed25519 private key PEM file")
    p_watch.add_argument("--creator", default="DAW Auto-Signer", help="Creator attribution")
    p_watch.add_argument("--project", help="Project attribution name")
    p_watch.add_argument("--auto-sign", action="store_true", default=True, help="Auto-generate manifest on file settle")
    p_watch.add_argument("--once", action="store_true", help="Run a single scan cycle and exit")

    # Permaweb command (IPFS CIDv1 & Arweave)
    p_permaweb = subparsers.add_parser("permaweb", help="Anchor manifest to IPFS CIDv1 and Arweave permaweb")
    p_permaweb.add_argument("--manifest", "-m", required=True, help="Manifest JSON file path")
    p_permaweb.add_argument("--ipfs-gateway", default="https://ipfs.io", help="IPFS gateway URL")
    p_permaweb.add_argument("--arweave-gateway", default="https://arweave.net", help="Arweave gateway URL")

    # Info command
    subparsers.add_parser("info", help="Display system information and audit log")

    # Serve command
    p_serve = subparsers.add_parser("serve", help="Start the Lysen Web Portal and REST API server")
    p_serve.add_argument("--host", default="0.0.0.0", help="Host interface to bind (default: 0.0.0.0)")
    p_serve.add_argument("--port", type=int, default=8000, help="Port to listen on (default: 8000)")

    args = parser.parse_args()

    if not args.command:
        parser.print_help()
        sys.exit(1)

    if args.command == "create":
        sys.exit(cmd_create(args))
    elif args.command == "verify":
        sys.exit(cmd_verify(args))
    elif args.command == "report":
        sys.exit(cmd_report(args))
    elif args.command == "migrate":
        sys.exit(cmd_migrate(args))
    elif args.command == "keys":
        if args.keys_command == "generate":
            sys.exit(cmd_keys_generate(args))
        else:
            p_keys.print_help()
            sys.exit(1)
    elif args.command == "ledger":
        sys.exit(cmd_ledger(args))
    elif args.command == "spatial":
        sys.exit(cmd_spatial(args))
    elif args.command == "wavelet":
        sys.exit(cmd_wavelet(args))
    elif args.command == "watch":
        sys.exit(cmd_watch(args))
    elif args.command == "permaweb":
        sys.exit(cmd_permaweb(args))
    elif args.command == "info":
        sys.exit(cmd_info(args))
    elif args.command == "serve":
        sys.exit(cmd_serve(args))
    else:
        parser.print_help()
        sys.exit(1)

if __name__ == "__main__":
    main()
