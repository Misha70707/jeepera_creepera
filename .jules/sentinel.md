## 2025-02-14 - Security Enhancement for MT5 Project
**Vulnerability:** Default `.gitignore` only covered MPS artifacts, leaving potential secrets (API keys, .env) and build artifacts exposed.
**Learning:** For a "Top Secret" algorithmic trading project using MT5 and Neural Networks, standard exclusions for Python (`venv`, `__pycache__`) and MQL5 (`*.ex5`, `*.set`, `MQL5/Files/`) are critical to prevent accidental leakage of proprietary strategies and credentials.
**Prevention:** Updated `.gitignore` to include comprehensive exclusion lists for Python, MQL5, and general security files. Validated using `git check-ignore`.
