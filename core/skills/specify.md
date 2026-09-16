# Specify skill

## Purpose

Define what outcome is required and why it matters without prescribing implementation.

## When to use

Use for features or behavior changes whose expected outcome, scope, or success criteria are not already explicit. A full specification is optional for a bugfix when expected behavior is clear.

## Inputs

- Task intent.
- Context brief.
- Stakeholder needs and constraints.

## Required context

- Verified current behavior relevant to the request.
- Users or systems affected.
- Known compatibility, policy, and scope constraints.

## Procedure

1. Define the problem and desired outcome.
2. State who or what is affected and why the change is needed.
3. Define observable behavior, in-scope and out-of-scope boundaries, and invariants.
4. Write measurable success criteria, including relevant failure and edge cases.
5. Record assumptions and unresolved product decisions.

## Output contract

Produce a specification containing:

- problem and rationale;
- desired observable behavior;
- scope and exclusions;
- constraints and invariants;
- measurable success criteria;
- assumptions and unresolved decisions.

## Constraints / must not do

- Define WHAT and WHY only.
- Do not choose architecture, files, algorithms, libraries, or implementation sequence.
- Do not silently resolve material ambiguity.

## Failure or escalation

Escalate when conflicting requirements or missing product decisions prevent testable success criteria. If expected behavior is already explicit, record it concisely and proceed without manufacturing a larger specification.
