# NORMATIVE REFERENCE ENVIRONMENT (V1.0.0)
# This container defines the canonical execution context for:
# - Golden vector generation
# - Deterministic hash computation
# - Cross-platform CI gates
#
# Python: 3.10.12
# fpcalc: 1.5.1
# BLAKE3: 1.3.3
# cryptography: 41.0.7
#
# Last regeneration: 2026-02-06 (golden-v1.0.1)

FROM python:3.10.12-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    libchromaprint-tools \
    ffmpeg \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements-locked.txt .
RUN pip install --no-cache-dir -r requirements-locked.txt

COPY . .

CMD ["python", "cli.py", "info"]
