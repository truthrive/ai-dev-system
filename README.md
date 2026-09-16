# AI Dev System

A reusable, context-first, specification-driven AI development system for coding agents.

AI Dev System exists to make development deliberate, changes small, and completion verifiable across technology stacks and coding agents. It provides a shared foundation for reusable rules, skills, and workflows, guided by evidence from real project work.

**Status: stable release (`1.0.0`).** Milestones 1 through 4 implement the technology-agnostic operating model, deterministic gates, verification-evidence contracts, preview-first project onboarding, and distribution via preview-first installation and safe versioned updates; see the [roadmap](docs/ROADMAP.md).

## Intended lifecycle

Intent → Context → Specification → Plan → Tasks → Implementation → Verification → Convergence → Evidence

Start with the desired outcome, inspect the project, and define success criteria before planning and implementing small tasks. Verification checks those criteria; convergence resolves gaps between the implementation and specification; evidence records what was checked and the results. Project-native checks remain authoritative, supplemented by the implemented read-only gates where applicable.

## Core operating model

Milestone 1 implements:

- six reusable rules for coding, architecture, testing, Git, documentation, and security;
- seven skills that separate context discovery, specification, planning, task breakdown, implementation, verification, and convergence;
- distinct workflows for features, bugfixes, and behavior-preserving refactors.

The [documentation index](docs/INDEX.md) routes agents to the implemented material. The feature workflow follows the full lifecycle. Bugfixes may use explicit expected behavior instead of manufacturing a full specification, while refactors establish a behavioral baseline before changing structure.

## Enforcement and onboarding

Milestone 2 adds:

- a [technology-agnostic gate contract](gates/CONTRACT.md) and runner for Git whitespace errors and broken relative Markdown links;
- a [verification and evidence contract](docs/verification-evidence.md) with explicit pass, fail, and blocked semantics;
- [preview-first onboarding](docs/onboarding.md) that discovers instructions, context, conventions, checks, documentation, and uncommitted work before creating a project-context file;
- reusable [project-context](templates/project-context.md) and [verification-evidence](templates/verification-evidence.md) templates;
- isolated fixture checks for non-destructive behavior and failure handling.

Onboarding creates no project instruction file and refuses to overwrite recognized context or operate on dirty active and legacy projects.

## Distribution and installation

Milestone 4 implements:

- a preview-first [installer](installer/install.ps1) for adopting AI Dev System in new and active projects with delimited `AGENTS.md` integration and SHA-256 manifest tracking;
- a safe [updater](installer/update.ps1) that validates local modifications, preserves project-owned context, and cleanly updates system-managed files;
- cross-platform PowerShell 5.1 and PowerShell Core 7 (`pwsh`) compatibility for deterministic execution on Windows and other supported platforms.

Preview installation into a target project:

```powershell
pwsh -NoProfile -File installer/install.ps1 -ProjectRoot <path>
```

Pass `-Apply` to install into `.ai-dev-system/` and link the project entrypoint. Use `installer/update.ps1 -ProjectRoot <path> -Apply` to update an existing project.

## Separation of concerns

- **Global reusable system:** shared principles and, when justified by repeated evidence, rules, skills, and workflows that apply across projects and agents. This repository holds that foundation.
- **Project-specific context:** a project's source, runtime behavior, architecture, constraints, and decisions. It belongs with the project and must be checked against its current implementation.
- **Temporary task state:** the current intent, specification, plan, tasks, and verification evidence. Its storage and retention conventions are not implemented.

## Intended project support

- **New projects:** establish context and success criteria before introducing implementation.
- **Active projects:** fit changes into existing conventions and preserve unrelated behavior.
- **Legacy projects:** inspect source and runtime to establish actual behavior before relying on potentially outdated documentation.

Prefer the simplest sufficient solution and surgical changes in every case. Completion requires verification evidence.

## Start here

Use [docs/INDEX.md](docs/INDEX.md) to find available documentation and see which areas are not implemented. Coding agents begin with [AGENTS.md](AGENTS.md).
