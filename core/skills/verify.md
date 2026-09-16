# Verify skill

## Purpose

Produce evidence that the implementation satisfies its success criteria and preserves required behavior.

## When to use

Use after implementation and before completion is claimed. Use again after any corrective change that affects prior evidence.

## Inputs

- Success criteria or explicit expected behavior.
- Implementation change set and record.
- Verification strategy and applicable testing rules.

## Required context

- Exact diff and affected behavior.
- Available project checks and relevant runtime environment.
- Known baseline failures and verification limitations.

## Procedure

1. Confirm the diff matches the intended scope.
2. Map each success criterion and preserved invariant to an executable check or other concrete evidence.
3. Run the narrowest relevant checks, then broader checks when risk or project policy requires them.
4. Record commands or actions, results, and evidence without omitting failures.
5. Distinguish implementation failures, environment failures, and pre-existing failures.
6. Identify criteria that remain unverified and why.

## Output contract

Produce a verification report containing:

- change and environment verified;
- criterion-to-evidence mapping;
- checks performed and exact outcomes;
- regression and compatibility evidence where relevant;
- failures, unverified scope, and confidence limits;
- a pass, fail, or blocked result.

## Constraints / must not do

- Do not change implementation while acting as verifier.
- Do not treat plans, code review, or assertions as execution evidence when runnable checks exist.
- Do not hide skipped checks or convert partial evidence into a pass.

## Failure or escalation

Report `fail` when evidence contradicts a criterion and `blocked` when required verification cannot run. Route implementation defects to Converge; escalate environment or access blockers with the evidence already collected.
