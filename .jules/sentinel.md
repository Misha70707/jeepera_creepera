## 2024-05-20 - Missing Strict Exclusions for Secrets and Core Artifacts

**Vulnerability:** The repository lacked `.gitignore` exclusions for critical files such as secrets (`.env`, `*.key`, `*.pem`), Python build artifacts, IDE configs, logs, and MT5 executables, creating a high risk of accidental leakage or repository pollution.

**Learning:** In repositories operating without active vulnerability scanning infrastructure, security must start with proactive environment hardening (e.g., rigid `.gitignore` rules) rather than reacting to code-level issues.

**Prevention:** Implement comprehensive and strict exclusions as a baseline security requirement for all new projects to prevent accidental commits of sensitive configuration or environment-specific data.
