# Security rule

## Scope

Applies when a task handles untrusted input, credentials, permissions, sensitive data, external systems, or security boundaries.

## Rules

- Identify relevant trust boundaries, assets, and abuse cases before implementation.
- Validate untrusted input at the boundary where it enters the system.
- Use least privilege for access, permissions, and external operations.
- Never embed, log, expose, or commit secrets or unnecessary sensitive data.
- Preserve existing security controls unless an approved change explicitly replaces them.
- Prefer established project security mechanisms over custom substitutes.
- Report material security assumptions, unresolved risks, and verification limits.
