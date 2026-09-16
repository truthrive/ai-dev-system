# Plan skill

## Purpose

Define how an approved outcome will be achieved within the current project.

## When to use

Use after the desired behavior and success criteria are clear, before implementation of work that requires more than a trivial direct change.

## Inputs

- Context brief.
- Approved specification or otherwise explicit expected behavior.
- Applicable rules and constraints.

## Required context

- Current architecture and relevant project conventions.
- Affected interfaces, dependencies, tests, and operational boundaries.
- Known risks and compatibility requirements.

## Procedure

1. Map each success criterion to the components and behavior likely to change.
2. Choose the simplest sufficient approach using existing boundaries and extension points.
3. Describe changes to data flow, interfaces, configuration, or architecture where applicable.
4. Define the verification strategy and evidence needed.
5. Identify ordering, migration, rollback, risks, assumptions, and decision points.
6. Check that the approach contains no unrelated refactor or speculative mechanism.

## Output contract

Produce a plan containing:

- chosen approach and rationale;
- affected areas and intended changes;
- interface, data, compatibility, and operational implications;
- verification strategy mapped to success criteria;
- risks, assumptions, dependencies, and rollback considerations;
- decisions still requiring approval.

## Constraints / must not do

- Define HOW; do not implement the change.
- Do not decompose work into a progress checklist; that belongs to Tasks.
- Do not add abstractions or scope unsupported by the specification and context.

## Failure or escalation

Return to Context when project reality is unclear, or to Specify when the expected outcome is ambiguous. Escalate decisions that materially change scope, behavior, compatibility, or risk.
