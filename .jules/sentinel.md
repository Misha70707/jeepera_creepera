## 2025-05-18 - Project Intent vs Repo Config Mismatch
**Vulnerability:** The project was initialized as an MPS project (with Java exclusions) but is intended for MT5/Python development, leaving it vulnerable to accidental commits of Python secrets and MT5 binaries.
**Learning:** Security configurations (like .gitignore) must align with the *planned* technology stack, not just the current file state. Early-stage repos are high-risk for leaking secrets if defaults are not adjusted immediately.
**Prevention:** Always cross-reference README/docs with .gitignore in new projects to ensure all planned technologies have security exclusions.
