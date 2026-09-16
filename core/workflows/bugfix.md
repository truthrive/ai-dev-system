# Bugfix workflow

Use when observed behavior is defective. Apply the relevant [rules](../rules/) throughout. A full specification is not required when expected behavior is already clear; record the expected behavior and regression criterion directly.

## Entry criteria

- The symptom, report, or failing evidence is available.
- The current branch and working tree have been inspected.

## Stages

1. **Context** — Use the [Context skill](../skills/context.md) to locate the affected behavior, constraints, history, and relevant tests without changing the project.
2. **Reproduce / Assess** — Reproduce the defect when practical. Otherwise assess the report and available evidence. Record actual behavior, expected behavior, conditions, impact, and a regression success criterion.
3. **Diagnose** — Trace the behavior to a supported root cause. Distinguish evidence from hypotheses and identify the smallest safe correction.
4. **Fix** — Use the [Implement skill](../skills/implement.md) to make the scoped correction and add focused regression coverage when practical. If diagnosis reveals a material design decision, use the [Plan skill](../skills/plan.md) first.
5. **Regression Verification** — Use the [Verify skill](../skills/verify.md) to show that the defect is resolved under the reproducing conditions and relevant existing behavior remains intact. Use [Converge](../skills/converge.md) if evidence fails or exposes gaps.

## Completion

The bugfix is complete only when root-cause evidence supports the fix, regression evidence supports the expected behavior, and no material verification gap remains.
