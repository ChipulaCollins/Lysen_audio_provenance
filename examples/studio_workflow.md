# Studio Automation Workflow Example

Using `cli.py` in automated DAW / CI pipelines:

```bash
#!/bin/bash
set -e

# Generate signing keys once per studio worker
python cli.py keys generate --output-dir ./keys

# Run provenance creation on exported master mix
python cli.py create \
  --input master_mix.wav \
  --key ./keys/ed25519_priv.pem \
  --creator "Lead Engineer" \
  --client "Record Label Inc" \
  --project "Album Master" \
  --software "ProTools 2024.3, Audio Provenance Tool 1.0.0" \
  --output master_mix.manifest.json \
  --pdf master_mix_report.pdf

# Verification step before archiving
python cli.py verify \
  --manifest master_mix.manifest.json \
  --audio master_mix.wav
```
