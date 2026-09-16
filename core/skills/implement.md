# Implement skill

## Purpose

Execute an approved change within its defined scope.

## When to use

Use after expected behavior and the implementation approach are sufficiently clear for scoped execution.

## Inputs

- Approved plan or direct fix approach.
- Executable task or tightly bounded change request.
- Success criteria and applicable rules.

## Required context

- Current source and working-tree state.
- Relevant interfaces, callers, tests, and project conventions.
- Known risks, constraints, and unrelated user changes.

## Procedure

1. Recheck the affected source and working tree immediately before editing.
2. Implement the smallest complete change for the current task.
3. Preserve existing behavior outside the approved scope.
4. Add or adjust focused tests and documentation when required by the change.
5. Run narrow development checks needed to catch immediate mistakes.
6. Review the resulting diff for scope, correctness, and accidental changes.
7. Record deviations from the plan and the reason for each.

## Output contract

Produce an implementation record containing:

- files changed and behavior implemented;
- tests or documentation changed;
- development checks run;
- deviations, assumptions, and known limitations;
- the change set ready for independent verification.

## Constraints / must not do

- Do not modify unrelated files or absorb unrelated working-tree changes.
- Do not broaden scope, refactor opportunistically, or add speculative abstractions.
- Do not claim that implementation checks constitute final verification.
- Do not conceal deviations from the approved approach.

## Failure or escalation

Stop and return to Plan or Tasks when implementation reveals a material design gap. Escalate when required access, destructive action, new dependency, or scope change lacks authorization.
