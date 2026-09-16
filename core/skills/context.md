# Context skill

## Purpose

Discover the current project reality needed to perform a task without changing it.

## When to use

Use at the start of work and whenever assumptions about existing behavior, constraints, or scope are uncertain.

## Inputs

- The task intent and known constraints.
- The project or subsystem in scope.
- Any supplied references, reports, or observed symptoms.

## Required context

- Repository instructions and relevant documentation.
- Current branch and working-tree state.
- Relevant source, configuration, tests, history, and runtime evidence available without mutation.

## Procedure

1. Restate the intent, scope, constraints, and unanswered questions.
2. Locate the relevant entrypoints, boundaries, dependencies, tests, and documentation.
3. Inspect source and configuration before trusting descriptive documentation.
4. Inspect runtime behavior or existing evidence when it is relevant and can be done read-only.
5. Separate verified facts, reasonable inferences, and unknowns.
6. Identify project conventions, existing changes, risks, and context still required for the next stage.

## Output contract

Produce a context brief containing:

- task intent and scope;
- relevant files, components, and boundaries;
- current behavior and supporting evidence;
- applicable conventions and constraints;
- existing unrelated working-tree changes;
- risks, unknowns, and blocking questions.

## Constraints / must not do

- Remain read-only: do not edit files, install dependencies, mutate data, or perform destructive commands.
- Do not propose implementation as established fact.
- Do not expand the task beyond the stated intent.

## Failure or escalation

If required context is unavailable, contradictory, unsafe to inspect, or dependent on a material product decision, stop at the verified facts and request the missing input. Do not invent project behavior.
