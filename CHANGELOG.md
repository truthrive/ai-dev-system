# Changelog

## [1.0.1] - 2026-09-17

### Added

- Added official MIT License and improved public adoption documentation with copyable paths and explicit Windows PowerShell 5.1 and PowerShell Core 7+ (`pwsh`) examples across Preview, Apply, onboarding, and update workflows.
- Added comprehensive multi-agent compatibility documentation covering Google Antigravity, Gemini CLI, OpenAI Codex, Cursor, GitHub Copilot (VS Code, Cloud Agent, Code Review, CLI, and GitHub.com Chat), and Claude Code, distinguishing vendor-documented support from AI Dev System integration test fixtures.
- Added regression test coverage in `tests/run.ps1` for fresh project installation followed by onboarding preview, apply, and pre-existing context collision protection (expanding automated checks to 29).
- Verified release candidate via an end-to-end remote-clone installation and onboarding smoke test in isolated temporary environments.

### Fixed

- Fixed onboarding context detection in `onboarding/onboard.ps1` to explicitly exclude the installed system template `.ai-dev-system/templates/project-context.md`, preventing false-positive blocking after a fresh installation while strictly preserving genuine project context protection.

## [1.0.0] - 2026-09-16

### Added

- Phase 1 repository foundation.
- Concise agent entrypoint, central documentation router, and ten-principle constitution.
- Six technology-agnostic rules for coding, architecture, testing, Git, documentation, and security.
- Seven lifecycle skills for context, specification, planning, tasks, implementation, verification, and convergence.
- Distinct feature, bugfix, and refactor workflows.
- Technology-agnostic gate and verification-evidence contracts with read-only Git diff and Markdown-link checks.
- Preview-first onboarding for new, active, and legacy projects with additive project-context generation.
- Project-context and verification-evidence templates.
- Preview-first installer (`installer/install.ps1`) for non-destructive deployment into target projects with delimited `AGENTS.md` integration and SHA-256 manifest tracking.
- Safe versioned updater (`installer/update.ps1`) preserving project-owned context (`PROJECT_CONTEXT.md`) and detecting local modifications to system files.
- Full compatibility with Antigravity (`GEMINI.md` and `.agents/rules/` recognition) and cross-platform runtime support across Windows PowerShell 5.1 and PowerShell Core 7 (`pwsh`).
- Comprehensive dependency-free verification test suite (22 automated checks) covering gates, onboarding, installer, updater, and non-destructive preservation behavior.

### Changed

- Expanded the README and documentation index to reflect stable `1.0.0` distribution status and installation procedures.
- Hardened Git execution across platforms to prevent native stderr redirection terminating exceptions under PowerShell StrictMode.
- Added cross-platform relative path resolution (`Get-RelativePathCompat`) supporting .NET Framework and .NET Core.
- Improved onboarding discovery for immediate child Git repositories, test setup/configuration files, and package declarations based on real-project validation.
