# Feature workflow

Use for new capabilities or intentional behavior changes. Apply the relevant [rules](../rules/) throughout.

## Entry criteria

- The requested outcome and initial scope are known.
- The current branch and working tree have been inspected.

## Stages

1. **Context** — Use the [Context skill](../skills/context.md) to establish current behavior, boundaries, constraints, and unknowns.
2. **Specify** — Use the [Specify skill](../skills/specify.md) to define WHAT, WHY, scope, invariants, and measurable success criteria.
3. **Plan** — Use the [Plan skill](../skills/plan.md) to define HOW the approved outcome will fit the current project and how it will be verified.
4. **Tasks** — Use the [Tasks skill](../skills/tasks.md) to create an ordered executable breakdown when the plan requires multiple units of work.
5. **Implement** — Use the [Implement skill](../skills/implement.md) to execute the approved scope without unrelated changes.
6. **Verify** — Use the [Verify skill](../skills/verify.md) to produce evidence for every success criterion and preserved invariant.
7. **Converge** — Use the [Converge skill](../skills/converge.md) to compare the specification, plan, tasks, implementation, and evidence; route remaining gaps back to the correct stage.

## Completion

The feature is complete only when convergence reports no material gaps, required documentation reflects actual behavior, and evidence supports the success criteria.
