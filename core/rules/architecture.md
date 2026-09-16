# Architecture rule

## Scope

Applies when a change affects component boundaries, dependencies, data flow, persistence, or externally visible interfaces.

## Rules

- Establish the current architecture from source, runtime behavior, and configuration before proposing a change.
- Preserve existing boundaries and dependency direction unless the approved plan requires otherwise.
- Prefer existing extension points and the least structural change that meets the need.
- Record a decision only when it has lasting architectural consequences or meaningful tradeoffs.
- State compatibility, migration, and rollback implications when they exist.
- Do not introduce layers, services, patterns, or abstractions for hypothetical future use.
