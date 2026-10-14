# Basic Create and Verify Example

```python
from security.keys import generate_keypair
from core.manifest import create_manifest
from security.verifier import verify_manifest_against_audio
from reporting.pdf_report import generate_pdf_report

# 1. Generate keypair
priv_key, pub_key = generate_keypair()

# 2. Create signed provenance manifest for WAV audio
manifest = create_manifest(
    audio_path="sample.wav",
    private_key=priv_key,
    creator="Producer Jane",
    client="Studio XYZ",
    project="Master Track"
)

# 3. Verify audio against manifest
result = verify_manifest_against_audio(manifest, "sample.wav", pub_key)
print(f"Is Valid: {result.is_valid}")
print(f"Signature Valid: {result.signature_valid}")

# 4. Generate PDF report
generate_pdf_report(manifest, "sample_report.pdf")
```
