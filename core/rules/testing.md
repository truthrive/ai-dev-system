# Testing rule

## Scope

Applies when defining or executing verification for a change.

## Rules

- Derive checks from explicit success criteria and observed project behavior.
- Use the narrowest deterministic checks that cover the changed behavior, then broaden only when risk justifies it.
- Test observable behavior and meaningful boundaries rather than duplicating implementation details.
- Include regression coverage for a reproduced defect when practical.
- Preserve relevant existing checks and distinguish new failures from pre-existing failures.
- Report the exact checks run, their results, and any unverified scope.
- Never claim completion from code inspection alone when executable verification is available.
