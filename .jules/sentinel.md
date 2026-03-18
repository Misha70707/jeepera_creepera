## 2024-05-24 - Missing strict gitignore for Python, MQL5, and Secrets
**Vulnerability:** The repository lacks strict `.gitignore` configurations for Python artifacts, MQL5 files (like compiled EX5 files or sensitive SET files), and secrets (like `.env`, `.pem`, etc.). This could lead to sensitive files being checked into the public repository.
**Learning:** This is an early-stage project without source code, but establishing a strict `.gitignore` is a critical first step for security and preventing secret leakage.
**Prevention:** Implement a comprehensive `.gitignore` that covers Python, MQL5, IDEs, logs, and secrets before any code is written.
