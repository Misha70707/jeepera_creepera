## 2024-05-14 - Infrastructure Hardening: Comprehensive Git Ignore Rules for Secrets

**Vulnerability:** The repository lacked `.gitignore` rules for common secret files, environment variables, logs, and compiled/executable assets (e.g., MT5 `*.ex5` and `*.set` files). This is a critical security gap in a new repository, as developers might accidentally commit sensitive data like API keys, environment configurations, or proprietary compiled logic.

**Learning:** When initializing a new repository or reviewing an early-stage project structure (especially a "Top Secret" one), the primary security vector is often accidental leakage of secrets or infrastructure configuration. Without active source code to scan, preventive infrastructure hardening—specifically via strict `.gitignore` configurations—is the highest priority defense mechanism.

**Prevention:** Ensure that comprehensive `.gitignore` files are established *before* active development begins. These should explicitly cover secrets, environment files, logs, IDE configurations, and domain-specific binaries/artifacts (like MT5 components) to provide defense-in-depth against accidental data exposure.
