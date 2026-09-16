# Changelog

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
