## 2025-11-14 - Hardened .gitignore to prevent secret leakage

**Vulnerability:** The repository lacked strict ignore rules for secrets (.env, keys) and framework artifacts (Python pycache, MT5 .ex5 files), which could lead to accidental commits of sensitive data and unnecessary binaries.

**Learning:** In early-stage or code-less repository states without explicit secret handling, the primary security focus must be preventive infrastructure hardening, such as strict `.gitignore` configurations, to ensure that future development (like MT5 and Python ML integration) doesn't leak secrets.

**Prevention:** Always establish comprehensive `.gitignore` rules mapping to the intended technology stack (Python, MQL5, etc.) and explicit secret file patterns before development begins. Verify the rules using dummy files to guarantee they function properly.
