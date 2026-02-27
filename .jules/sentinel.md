## 2025-02-17 - Repository Hardening
**Vulnerability:** Default repositories often expose sensitive artifacts (secrets, keys, binaries) if not explicitly ignored, leading to credential leaks and bloated git history.
**Learning:** Even without application code, establishing a robust security perimeter via `.gitignore` is a critical "Day 0" defense.
**Prevention:** Implemented comprehensive exclusion rules for secrets (`.env`, `*.key`), Python artifacts (`venv`, `__pycache__`), and MT5 binaries (`*.ex5`, `*.set`) to prevent accidental committal.
