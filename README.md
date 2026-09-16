# AI Dev System

A reusable, context-first, specification-driven AI development system for coding agents.

AI Dev System exists to make development deliberate, changes small, and completion verifiable across technology stacks and coding agents. It provides a shared foundation for reusable rules, skills, and workflows, guided by evidence from real project work.

**Status: early development (`0.1.0-dev`).** Milestone 1 provides the technology-agnostic core operating model. Automated gates, project onboarding, installer, templates, and distribution remain future work; see the [roadmap](docs/ROADMAP.md).

## Intended lifecycle

Intent → Context → Specification → Plan → Tasks → Implementation → Verification → Convergence → Evidence

Start with the desired outcome, inspect the project, and define success criteria before planning and implementing small tasks. Verification checks those criteria; convergence resolves gaps between the implementation and specification; evidence records what was checked and the results. Deterministic quality gates are an intended part of verification, with implementation deferred to a later phase.

## Core operating model

Milestone 1 implements:

- six reusable rules for coding, architecture, testing, Git, documentation, and security;
- seven skills that separate context discovery, specification, planning, task breakdown, implementation, verification, and convergence;
- distinct workflows for features, bugfixes, and behavior-preserving refactors.

The [documentation index](docs/INDEX.md) routes agents to the implemented material. The feature workflow follows the full lifecycle. Bugfixes may use explicit expected behavior instead of manufacturing a full specification, while refactors establish a behavioral baseline before changing structure.

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
