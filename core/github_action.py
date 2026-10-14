"""GitHub Action Automated C2PA Audio Provenance Runner for CI/CD Pipelines.

Automates signing and embedding C2PA manifests into rendered game audio assets or podcasts
during automated GitHub Actions workflow runs.
"""

import os
import sys
import json
from cryptography.hazmat.primitives.asymmetric import ed25519
from core.manifest import create_manifest


def run_github_action(audio_dir: str, private_key_hex: str) -> None:
    """Executes CI/CD automated signing across all audio files in build artifact directory."""
    if not os.path.exists(audio_dir):
        print(f"::error::Directory not found: {audio_dir}")
        sys.exit(1)

    private_key = ed25519.Ed25519PrivateKey.from_private_bytes(bytes.fromhex(private_key_hex))
    signed_count = 0

    for root, _, files in os.walk(audio_dir):
        for f in files:
            if f.endswith((".wav", ".flac")):
                audio_path = os.path.join(root, f)
                manifest = create_manifest(
                    audio_path=audio_path,
                    private_key=private_key,
                    creator="CI/CD Build Pipeline",
                    project=f"Automated Build Artifact ({f})",
                )
                output_manifest = audio_path + ".c2pa.json"
                with open(output_manifest, "w", encoding="utf-8") as mf:
                    json.dump(manifest, mf, indent=2)
                signed_count += 1
                print(f"::notice::Signed asset: {f} -> {output_manifest}")

    print(f"::set-output name=signed_count::{signed_count}")


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python -m core.github_action <audio_dir> <private_key_hex>")
        sys.exit(1)

    run_github_action(sys.argv[1], sys.argv[2])
