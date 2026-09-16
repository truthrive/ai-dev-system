# Gate contract

A gate is a deterministic, read-only check that converts defined project inputs into an explicit result and evidence. Gates supplement project-native checks; they do not replace them.

## Required definition

Every gate must define:

- a stable identifier and purpose;
- when it applies and the inputs it reads;
- the exact check performed;
- `PASS`, `FAIL`, `BLOCKED`, and, when conditional, `SKIP` conditions;
- evidence emitted for the result;
- known coverage limits.

## Execution rules

- Use the same inputs to produce the same result, apart from declared environment facts.
- Remain read-only: do not format files, install tools, fetch data, or repair failures.
- Prefer project-native commands when their behavior is already defined by the project.
- Treat a missing required tool or unreadable required input as `BLOCKED`, not `PASS`.
- Treat an inapplicable optional check as `SKIP`; a skipped gate supplies no evidence for a criterion.
- Never include secrets or unnecessary sensitive data in evidence.

## Runner interface

Run the implemented gates from a project root:

```powershell
pwsh -NoProfile -File gates/run.ps1 -ProjectRoot <path>
```

Use `-OutputFormat Json` for structured output. The runner exits with `0` when all applicable gates pass, `1` when any gate fails, and `2` when no gate fails but at least one gate is blocked.

## Implemented gates

| ID | Applies when | Check | Coverage limit |
| --- | --- | --- | --- |
| `git.diff-check` | The target is in a Git work tree | Runs `git diff --check` for unstaged and staged changes | Does not inspect untracked file content |
| `docs.local-links` | Markdown files are present | Confirms relative local link targets exist | Does not validate anchors, absolute paths, or remote URLs |

The runner emits the gate ID, status, summary, and relevant details. Its output is evidence input and must be recorded under the [verification and evidence contract](../docs/verification-evidence.md).

Repository access failures preserve Git's diagnostic and block both checks without filesystem fallback. Discovery uses the exclusions and symbolic-link restrictions documented in [onboarding](../docs/onboarding.md); excluded files are outside gate coverage.
