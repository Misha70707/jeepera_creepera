## 2026-02-26 - Missing Security Exclusions
**Vulnerability:** Sensitive files (.env, keys, logs) were not excluded from version control, creating a risk of accidental secret leakage.
**Learning:** Default repository configurations often lack security-specific exclusions, focusing only on build artifacts (like MPS gen files).
**Prevention:** Always initialize repositories with a comprehensive security-focused `.gitignore` that explicitly excludes secrets, credentials, and environmental configurations.
