## 2024-05-14 - Proactive Secret Management in Early-Stage Repositories
**Vulnerability:** The repository lacked basic gitignore rules for secrets, keys, and MT5-specific files (`.env`, `*.key`, `*.ex5`), creating a high risk of accidental secret leakage or committing sensitive binaries.
**Learning:** In code-less or early-stage "Top Secret" project repositories, vulnerability hunting shifts from source code scanning to preventative infrastructure hardening. Strict `.gitignore` configurations act as the first line of defense against data exposure.
**Prevention:** Implement comprehensive `.gitignore` files from the project's inception, specifically tailored to the technology stack (e.g., Python, MQL5, JetBrains) to proactively exclude secrets, logs, and artifacts.
