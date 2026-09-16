# Coding rule

## Scope

Applies when changing executable source or configuration.

## Rules

- Read the affected code and its callers, consumers, and tests before editing.
- Follow the project's established conventions unless the task explicitly changes them.
- Implement the smallest complete change that satisfies the approved scope.
- Keep changes local; do not refactor, rename, reformat, or clean up unrelated code.
- Handle relevant error paths and boundary conditions without speculative generalization.
- Avoid new abstractions until repeated concrete use demonstrates a need.
- Keep implementation and verification separate: implementation produces the change; verification produces evidence about it.
