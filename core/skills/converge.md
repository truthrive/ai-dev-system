# Converge skill

## Purpose

Compare the delivered change and its evidence with the specification, plan, and tasks to determine what remains before completion.

## When to use

Use after verification, and repeat after corrective work until the approved outcome is supported by evidence or a blocker is accepted.

## Inputs

- Specification or explicit expected behavior.
- Approved plan and task list where they exist.
- Implementation diff and record.
- Verification report and evidence.

## Required context

- Current working-tree and branch state.
- All success criteria, planned changes, task outcomes, and known deviations.
- Verification failures, gaps, and limitations.

## Procedure

1. Compare implementation behavior with every success criterion.
2. Compare the diff with the approved plan and task scope.
3. Check that required tasks are complete and deviations are explained.
4. Evaluate whether verification evidence supports each completion claim.
5. Classify remaining gaps as implementation, specification, planning, task, evidence, or external blockers.
6. Define the smallest next action and route it to the appropriate lifecycle stage.
7. Declare convergence only when no material gap remains and evidence supports completion.

## Output contract

Produce a convergence report containing:

- status: converged, not converged, or blocked;
- criterion, plan, and task coverage;
- evidence supporting completed outcomes;
- deviations and remaining gaps;
- owner or lifecycle stage for each next action;
- final completion evidence when converged.

## Constraints / must not do

- Verification evidence is required; absence of evidence cannot produce `converged`.
- Do not change code, rewrite requirements, or waive gaps silently during comparison.
- Do not demand artifacts that the task did not require when explicit behavior and evidence are sufficient.

## Failure or escalation

Route defects to Implement, design gaps to Plan, unclear outcomes to Specify, missing breakdown to Tasks, and insufficient evidence to Verify. Escalate only when a material decision, authorization, or external blocker prevents the next action.
