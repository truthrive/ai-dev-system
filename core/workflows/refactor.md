# Refactor workflow

Use for structural changes intended to preserve observable behavior. Apply the relevant [rules](../rules/) throughout.

## Entry criteria

- The reason, scope, and intended structural outcome are explicit.
- Any behavior change is excluded or separately specified and approved.
- The current branch and working tree have been inspected.

## Stages

1. **Baseline** — Record the observable behavior and run relevant existing checks before editing. If the baseline fails, capture the failures and decide whether they block safe comparison.
2. **Context** — Use the [Context skill](../skills/context.md) to inspect the structure, callers, dependencies, boundaries, and conventions in scope.
3. **Plan** — Use the [Plan skill](../skills/plan.md) to define the smallest structural change, ordering, risk controls, and behavioral verification strategy.
4. **Implement** — Use the [Implement skill](../skills/implement.md) to make the scoped structural change without intentional behavior changes or unrelated cleanup.
5. **Behavioral Verification** — Use the [Verify skill](../skills/verify.md) to compare post-change behavior and checks with the baseline. Use [Converge](../skills/converge.md) if evidence identifies a behavioral difference, plan deviation, or gap.

## Completion

The refactor is complete only when evidence shows required behavior is preserved, the approved structural outcome is achieved, and all material differences from the baseline are explained and accepted.
