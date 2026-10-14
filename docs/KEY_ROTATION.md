# Key Rotation & Security Guide

## Ed25519 Key Management

- Keypairs are stored in PEM format.
- `key_id` is computed as `blake3:<hex>` over raw 32-byte Ed25519 public key.

## Key Rotation Procedure

1. Generate a new keypair using:
   ```bash
   python cli.py keys generate --output-dir ~/.audio_provenance/keys_v2
   ```
2. Existing manifests remain valid because each manifest contains the public key embedded in its signature block.
3. Update production signing servers with the new private key PEM path.
