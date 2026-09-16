# Tasks skill

## Purpose

Turn an approved plan into an ordered, executable breakdown with clear completion checks.

## When to use

Use when a plan spans multiple changes, dependencies, or verification steps that should be executed and reviewed separately.

## Inputs

- Approved plan.
- Specification or explicit expected behavior.
- Context brief and applicable rules.

## Required context

- Affected files or components known from the plan.
- Dependencies and required execution order.
- Success criteria and verification strategy.

## Procedure

1. Split the plan into the smallest coherent units that produce reviewable progress.
2. Order units by dependency and risk.
3. Give each task a scope, action, expected result, and verification check.
4. Include documentation and compatibility work only where the plan requires it.
5. Map all success criteria to at least one task or final verification step.
6. Remove duplicate, unrelated, and speculative tasks.

## Output contract

Produce an ordered task list in which every task states:

- objective;
- explicit scope;
- prerequisites;
- expected result;
- completion evidence.

Also identify the final verification step and any blocked tasks.

## Constraints / must not do

- Do not implement tasks or change project files.
- Do not redesign the approved plan during decomposition.
- Do not create administrative tasks without an observable deliverable.

## Failure or escalation

Return to Plan if a task cannot be made executable without inventing design decisions. Escalate missing dependencies or approvals that block safe execution.
