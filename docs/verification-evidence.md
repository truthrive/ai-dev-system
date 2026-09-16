# Verification and evidence contract

Verification shows whether a specific change satisfies its success criteria. Evidence is the reproducible record supporting that conclusion.

## Required record

A verification report must contain:

- the change, revision, and environment verified;
- each success criterion and the evidence that supports or contradicts it;
- each command or manual check performed, with its result and relevant output;
- applicable gate results, including `SKIP` and `BLOCKED` outcomes;
- regression, compatibility, or baseline comparisons where relevant;
- unverified scope, known limitations, and pre-existing failures;
- an overall result of `PASS`, `FAIL`, or `BLOCKED`.

## Result rules

- `PASS` requires evidence for every material success criterion and no unresolved failing gate or regression.
- `FAIL` means evidence contradicts at least one material criterion.
- `BLOCKED` means required evidence cannot be obtained; it is not a pass.
- A skipped check supports no criterion and must be explained when its absence matters.
- Evidence must identify what actually ran. Planned commands, assertions, and code inspection are not execution evidence.

Use the [verification evidence template](../templates/verification-evidence.md) when a durable report is needed. Do not include secrets or unrelated sensitive output.
