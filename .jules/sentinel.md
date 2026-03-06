## 2025-01-15 - Missing Preventive Infrastructure Hardening
**Vulnerability:** The repository lacked `.gitignore` exclusions for critical secret files (`.env`, `*.key`, `*.pem`), IDE configs, logs, Python artifacts, and MT5-specific files (`*.set`, `*.ex5`). This could lead to accidental commitment of sensitive data and credentials.
**Learning:** In projects without existing source code, preventive infrastructure hardening (like strict `.gitignore` rules) is a critical defense-in-depth measure to prevent secret leakage before development begins.
**Prevention:** Implement strict version control exclusions for secrets, credentials, environment configurations, and build artifacts at the inception of the project. Always assume files will be accidentally committed unless explicitly ignored.
