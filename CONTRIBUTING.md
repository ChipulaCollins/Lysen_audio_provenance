# Contributing to Lysen

Thank you for your interest in contributing to Lysen! This document outlines our development workflow, coding standards, and governance policies.

---

## 1. Development Environment Setup

### Prerequisites
- Python 3.10+
- Flutter 3.20+ (for GUI and Flutter tests)
- `ffmpeg` and `fpcalc` (Chromaprint tools)

### Quick Setup
```bash
# Clone the repository
git clone https://github.com/lysen-audio/audio_provenance.git
cd audio_provenance

# Install Python development dependencies in editable mode
pip install -e .[dev]

# Verify installation
python -m pytest tests/ -v
flutter test
```

---

## 2. Testing & Quality Standards

- **Unit & Integration Tests:** All Python tests must pass (`python -m pytest tests/ -v`).
- **Flutter Widget Tests:** Must pass cleanly without pending timers or memory leaks (`flutter test`).
- **Code Formatting:** Adhere to PEP 8 standards for Python and `dart format` for Dart.
- **Determinism:** Any changes to audio parsing, JSON canonicalization, or hashing MUST maintain byte-level determinism.

---

## 3. Golden Vector Governance

The files in `tests/golden_vectors/` are normative cryptographic references.

### Strict Governance Rules:
1. **Never** regenerate golden vectors to mask a failing test.
2. Vectors may only be updated when fixing a verified canonicalization specification bug or handling an upstream normative dependency change.
3. Every vector update must reference an open issue and follow the procedure documented in `tests/golden_vectors/README.md`.

---

## 4. Submitting a Pull Request (PR)

1. Fork the repository and create your feature branch (`git checkout -b feature/amazing-feature`).
2. Commit your changes with descriptive commit messages (`git commit -m 'feat: add support for BWF broadcast audio extension chunks'`).
3. Ensure CI passes locally:
   ```bash
   pytest tests/ -v
   flutter test
   flutter analyze
   ```
4. Push to the branch (`git push origin feature/amazing-feature`).
5. Open a Pull Request detailing the changes, benchmarks, and threat model impact.
