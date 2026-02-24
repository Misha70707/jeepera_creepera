## 2024-05-22 - Configuration Drift in Early Stage Repo
**Vulnerability:** Critical security exclusions (.env, keys) were documented as enforced but missing from .gitignore.
**Learning:** Early-stage repositories often have "aspirational" documentation that doesn't match the actual code state. Trust code over docs/memory.
**Prevention:** Always verify configuration files against security standards, regardless of what documentation claims.
