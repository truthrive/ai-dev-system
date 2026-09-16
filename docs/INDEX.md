# Documentation index

This is the central router for AI Dev System. Start with the constitution, select the workflow that matches the work, and load only its relevant rules and skills.

| Area | Location | Status |
| --- | --- | --- |
| Constitution | [Default constitution](../core/constitution/default.md) | Available: shared development principles |
| Roadmap | [ROADMAP.md](ROADMAP.md) | Available: milestone outcomes |
| Onboarding | [onboarding.md](onboarding.md) | Available: preview-first onboarding for new, active, and legacy projects |
| Verification evidence | [verification-evidence.md](verification-evidence.md) | Available: required evidence fields and result semantics |
| Architecture docs | [architecture/](architecture/) | Not implemented; reserved for system architecture documentation |
| Decisions | [decisions/](decisions/) | Not implemented; reserved for architectural decision records |
| Rules | See below | Available: six technology-agnostic rules |
| Skills | See below | Available: seven lifecycle skills |
| Workflows | See below | Available: feature, bugfix, and refactor |
| Gates | [Gate contract](../gates/CONTRACT.md) and [runner](../gates/run.ps1) | Available: Git diff and local Markdown-link checks |
| Templates | [Project context](../templates/project-context.md) and [verification evidence](../templates/verification-evidence.md) | Available |
| Installer | [installer/](../installer/) | Not implemented |
| Tests | [M2 verification harness](../tests/run.ps1) | Available: isolated gate and onboarding fixtures |

## Rules

- [Coding](../core/rules/coding.md)
- [Architecture](../core/rules/architecture.md)
- [Testing](../core/rules/testing.md)
- [Git](../core/rules/git.md)
- [Documentation](../core/rules/docs.md)
- [Security](../core/rules/security.md)

## Skills

- [Context](../core/skills/context.md) — discover current reality; read-only
- [Specify](../core/skills/specify.md) — define WHAT and WHY
- [Plan](../core/skills/plan.md) — define HOW
- [Tasks](../core/skills/tasks.md) — create an executable breakdown
- [Implement](../core/skills/implement.md) — execute the approved scope
- [Verify](../core/skills/verify.md) — produce evidence against success criteria
- [Converge](../core/skills/converge.md) — compare outcomes and evidence, then route remaining gaps

## Workflows

- [Feature](../core/workflows/feature.md) — new capabilities or intentional behavior changes
- [Bugfix](../core/workflows/bugfix.md) — defects with reproduction or assessment, diagnosis, correction, and regression verification
- [Refactor](../core/workflows/refactor.md) — structural change with baseline and behavioral preservation

## Enforcement and onboarding

- Use the [gate contract and runner](../gates/CONTRACT.md) for the implemented read-only deterministic checks.
- Follow the [verification and evidence contract](verification-evidence.md) when reporting results.
- Use [project onboarding](onboarding.md) to inspect a target and create a missing project-context file without replacing existing work.

See the [README](../README.md) for scope and intended lifecycle, [VERSION](../VERSION) for the development version, and [CHANGELOG](../CHANGELOG.md) for recorded changes. Add routes as real documentation or implementations become available.
