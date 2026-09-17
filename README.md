# AI Dev System

A reusable, context-first, specification-driven AI development system for coding agents.

AI Dev System makes AI-assisted software development deliberate, changes surgical, and completion verifiable across technology stacks and coding agents. It provides a shared, technology-agnostic foundation of rules, skills, workflows, deterministic gates, and non-destructive distribution.

**Status: Stable Release (`1.0.0`).** Milestone 1 through Milestone 4 outcomes are complete and verified; see the [Roadmap](docs/ROADMAP.md) and [Changelog](CHANGELOG.md).

---

## Value Proposition & Supported Use Cases

Most AI coding assistants struggle with context drift, unconstrained refactoring, and unverifiable claims of completion. AI Dev System establishes a disciplined development lifecycle:

- **New Projects:** Establish context, architecture boundaries, and success criteria before writing code.
- **Active Projects:** Discover existing conventions, test suites, and instruction files without clobbering established project practices or modifying unrelated code.
- **Legacy Projects:** Ground agent decisions in runtime and source code reality, documenting documentation drift and risk before modernizing or refactoring.

---

## Quick Start

### Prerequisites
- **Git**: A standard Git installation available in `PATH`.
- **PowerShell Runtime**: Supported on Windows PowerShell 5.1 (pre-installed on Windows) or PowerShell Core 7+ (`pwsh`) on Windows, macOS, or Linux. Note that `pwsh` is not installed by default.

### 1. Clone the Stable Release
Clone the stable `v1.0.0` release tag:
```bash
git clone --branch v1.0.0 https://github.com/truthrive/ai-dev-system.git
cd ai-dev-system
```

### 2. Preview Installation (Read-Only)
Set a target project directory variable (replace `"C:\Projects\my-app"` with your actual project path) and preview planned additions and instruction integrations without writing files:

Using Windows PowerShell 5.1:
```powershell
$Target = "C:\Projects\my-app"
powershell -ExecutionPolicy Bypass -File installer/install.ps1 -ProjectRoot $Target
```

Or using PowerShell Core 7+ (`pwsh`):
```powershell
$Target = "C:\Projects\my-app"
pwsh -NoProfile -File installer/install.ps1 -ProjectRoot $Target
```

### 3. Apply Installation & Review Git Changes
Deploy AI Dev System into your target project:

Using Windows PowerShell 5.1:
```powershell
powershell -ExecutionPolicy Bypass -File installer/install.ps1 -ProjectRoot $Target -Apply
```

Or using PowerShell Core 7+ (`pwsh`):
```powershell
pwsh -NoProfile -File installer/install.ps1 -ProjectRoot $Target -Apply
```

> [!IMPORTANT]
> **Commit installation changes before onboarding:** AI Dev System does not automatically commit changes in your target project. In an existing Git repository, review the added `.ai-dev-system/` files and the modified `AGENTS.md` using your standard Git workflow (`git status`, `git diff`) and commit them (`git commit`) before continuing. Onboarding in Step 4 strictly requires a clean Git work tree to establish an accurate project baseline.

### 4. Onboard the Project
Once installation changes are committed and the working tree is clean, run onboarding to discover your project's conventions and generate an initial additive project-context file:

Using Windows PowerShell 5.1:
```powershell
# Preview discovery:
powershell -ExecutionPolicy Bypass -File onboarding/onboard.ps1 -ProjectRoot $Target -ProjectType Active

# Apply discovery (creates .ai-dev-system/PROJECT_CONTEXT.md):
powershell -ExecutionPolicy Bypass -File onboarding/onboard.ps1 -ProjectRoot $Target -ProjectType Active -Apply
```

Or using PowerShell Core 7+ (`pwsh`):
```powershell
# Preview discovery:
pwsh -NoProfile -File onboarding/onboard.ps1 -ProjectRoot $Target -ProjectType Active

# Apply discovery (creates .ai-dev-system/PROJECT_CONTEXT.md):
pwsh -NoProfile -File onboarding/onboard.ps1 -ProjectRoot $Target -ProjectType Active -Apply
```

Review the generated `.ai-dev-system/PROJECT_CONTEXT.md`, refine any unverified statements, and commit it using your project's normal review process.

---

## What the Installer Manages

The installer implements non-destructive defaults and path checks:

### Files Created in Target Project
The installer deploys the self-contained system runtime into `<target>/.ai-dev-system/`:
- **`core/`**: Ten-principle [constitution](core/constitution/default.md), rules (coding, architecture, testing, git, docs, security), lifecycle skills (context, specify, plan, tasks, implement, verify, converge), and workflows (feature, bugfix, refactor).
- **`docs/`**: Central router ([INDEX.md](docs/INDEX.md)), verification evidence contract, and onboarding guide.
- **`gates/`**: Deterministic read-only gate runner (`run.ps1`) and [gate contract](gates/CONTRACT.md).
- **`onboarding/`**: Discovery engine and onboarding runner (`onboard.ps1`).
- **`templates/`**: Reusable templates for project context and verification evidence.
- **`installer/`**: Portable `install.ps1` and `update.ps1` scripts.
- **`VERSION`**: Target installed version identifier.
- **`manifest.json`**: Cryptographic SHA-256 hash manifest tracking system-managed files to detect local modifications during update.

### Entrypoint Integration (`AGENTS.md`)
- **New `AGENTS.md`**: Created if not already present in the target project root, routing agents to `.ai-dev-system/docs/INDEX.md`.
- **Existing `AGENTS.md`**: Updated non-destructively by inserting or updating a clearly delimited block:
  ```markdown
  <!-- AI-DEV-SYSTEM:START -->
  ...
  <!-- AI-DEV-SYSTEM:END -->
  ```
  All existing project instructions outside the delimiters remain untouched.

### Files Strictly Preserved
- **`.ai-dev-system/PROJECT_CONTEXT.md`**: Project-owned file generated during onboarding. The installer and updater **never** overwrite, remove, or alter this file.

---

## Agent Compatibility & Configuration

AI Dev System uses technology-agnostic Markdown rather than vendor-specific plugins or IDE extensions. Recognizing `AGENTS.md` acts only as an entrypoint router; it **does not** automatically load or inject all files under `.ai-dev-system/` into an agent's context. Agents must navigate and load linked rules, skills, and workflows on demand as their tasks require.

### Supported Coding Agents

| Agent / Environment | Native `AGENTS.md` Support | Alternative Configuration / Instructions | Integration Status with AI Dev System |
| --- | --- | --- | --- |
| **Google Antigravity** | Yes (workspace root) | Also discovers `GEMINI.md` and `.agents/rules/*.md` | **Verified**: Automatic instruction discovery and rule injection verified live; progressive disclosure via linked skills. |
| **Gemini CLI** | Yes (workspace root) | Also discovers `GEMINI.md` | **Verified**: Instruction discovery verified in onboarding fixtures. |
| **OpenAI Codex** | Yes (pioneered `AGENTS.md`) | Custom prompt / system instructions | **Verified**: Onboarding discovery and initial milestone development used `AGENTS.md`. |
| **Cursor** | Yes (recent versions) | [`.cursorrules`](https://docs.cursor.com/context/rules-for-ai) or [`.cursor/rules/*.md`](https://docs.cursor.com/context/rules-for-ai) | **Configured via pointer**: Discovered by onboarding; requires manual pointer to `AGENTS.md` or `.ai-dev-system/` if not using native discovery. |
| **GitHub Copilot (VS Code)** | Yes (Copilot Chat) | [`.github/copilot-instructions.md`](https://code.visualstudio.com/docs/copilot/customization/custom-instructions) or [path-specific instructions](https://docs.github.com/en/copilot/reference/custom-instructions-support) | **Supported via discovery**: Instruction discovery verified in onboarding fixtures (`AGENTS.md` and `.github/copilot-instructions.md`). |
| **GitHub Copilot (Cloud Agent)** | Yes ([vendor-documented](https://docs.github.com/en/copilot/reference/custom-instructions-support)) | [`.github/copilot-instructions.md`](https://docs.github.com/en/copilot/reference/custom-instructions-support), `CLAUDE.md`, or `GEMINI.md` | **Vendor-documented**: Native `AGENTS.md` support documented across GitHub.com and supported IDEs; not verified in AI Dev System integration tests. |
| **GitHub Copilot (Code Review)** | Yes ([vendor-documented](https://docs.github.com/en/copilot/reference/custom-instructions-support)) | [`.github/copilot-instructions.md`](https://docs.github.com/en/copilot/reference/custom-instructions-support) or path-specific instructions | **Vendor-documented**: `AGENTS.md` support documented on GitHub.com and selected IDEs; not verified in AI Dev System integration tests. |
| **GitHub Copilot (CLI)** | Yes ([vendor-documented](https://docs.github.com/en/copilot/reference/custom-instructions-support)) | [`.github/copilot-instructions.md`](https://docs.github.com/en/copilot/reference/custom-instructions-support), `~/.copilot/copilot-instructions.md`, `CLAUDE.md`, or `GEMINI.md` | **Vendor-documented**: Native `AGENTS.md` support documented by GitHub; not verified in AI Dev System integration tests. |
| **GitHub.com (Copilot Chat)** | No (uses repo, personal, or org instructions) | [`.github/copilot-instructions.md`](https://docs.github.com/en/copilot/reference/custom-instructions-support) | **Configured via pointer**: Discovered by onboarding; requires adding an instruction pointer referencing `.ai-dev-system/docs/INDEX.md`. |
| **Claude Code** | No | [`CLAUDE.md`](https://docs.anthropic.com/en/docs/agents-and-tools/claude-code) | **Configured via pointer**: Discovered by onboarding; requires adding an instruction pointer referencing `.ai-dev-system/docs/INDEX.md`. |

### Important Operational Boundaries
- **No Automatic Bulk-Context Ingestion**: Discovering `AGENTS.md` loads only top-level router instructions. It does not preload every rule, skill, or workflow into agent context.
- **Vendor Capabilities vs. Verified Integration**: Vendors document custom instruction capabilities and file conventions (such as GitHub's [custom instructions support](https://docs.github.com/en/copilot/reference/custom-instructions-support)). AI Dev System automated integration tests specifically verify onboarding discovery of `AGENTS.md` and `.github/copilot-instructions.md`. Full end-to-end task execution across third-party cloud agents, review bots, or CLI environments has not been independently benchmarked.
- **Tool Requirements**: All agents require shell execution capabilities (Windows PowerShell 5.1 or PowerShell Core 7+) and Git to run gates, verification checks, and onboarding scripts.

---

## Installation vs. Project Onboarding

AI Dev System strictly separates installing the engine from learning a project:
- **Installation (`installer/install.ps1`)**: Deploys system files into `.ai-dev-system/` and configures `AGENTS.md`. It does not inspect project source code or infer build commands.
- **Project Onboarding (`onboarding/onboard.ps1`)**: Inspects the target project's reality—existing instructions, package declarations, test configurations, Git status, and uncommitted changes—and generates a tailored `.ai-dev-system/PROJECT_CONTEXT.md`. Onboarding never alters project source code or existing instruction files.

---

## Updating an Installed Project

When updating AI Dev System to a newer version:

### 1. Preview Update
Set your target project path (replacing `"C:\Projects\my-app"` with your actual project path) and inspect added, updated, removed, and preserved files:

Using Windows PowerShell 5.1:
```powershell
$Target = "C:\Projects\my-app"
powershell -ExecutionPolicy Bypass -File installer/update.ps1 -ProjectRoot $Target
```

Or using PowerShell Core 7+ (`pwsh`):
```powershell
$Target = "C:\Projects\my-app"
pwsh -NoProfile -File installer/update.ps1 -ProjectRoot $Target
```

### 2. Apply Update
Apply updates cleanly:

Using Windows PowerShell 5.1:
```powershell
powershell -ExecutionPolicy Bypass -File installer/update.ps1 -ProjectRoot $Target -Apply
```

Or using PowerShell Core 7+ (`pwsh`):
```powershell
pwsh -NoProfile -File installer/update.ps1 -ProjectRoot $Target -Apply
```

### Safety Checks During Update
- **Context Preservation**: `.ai-dev-system/PROJECT_CONTEXT.md` is strictly project-owned and preserved.
- **Modification Detection**: If an installed file's hash differs from the recorded manifest hash, update halts before overwriting it (override requires `-Force`).
- **Manifest Path Validation**: The updater validates each entry read from `manifest.json` using `Test-SafeManifestPath`. Paths that are empty, rooted, contain traversal segments (`..` or `.`), or target project-owned files (`PROJECT_CONTEXT.md`, `manifest.json`) are rejected before executing file removals or updates.

---

## Troubleshooting

- **Target Git work tree has uncommitted changes**:
  - *Cause*: Both the installer and onboarding require a clean Git work tree before applying changes to ensure clean rollback boundaries.
  - *Resolution*: Review changes with `git status`, then commit (`git commit`) or stash (`git stash`) them before retrying with `-Apply`.
- **Target already contains conflicting files**:
  - *Cause*: Running a fresh install against a project that already has `.ai-dev-system/` files not tracked by a source manifest.
  - *Resolution*: Run `installer/update.ps1` instead, or pass `-Force` if intentionally replacing unmanaged collisions.
- **Locally modified system files detected**:
  - *Cause*: One or more files inside `.ai-dev-system/` were edited manually.
  - *Resolution*: Review differences with `git diff .ai-dev-system/`. If the changes should be overwritten by the release files, pass `-Force`.
- **Git ownership or permission errors**:
  - *Cause*: Running across different user accounts, network shares, or container mount boundaries where Git detects a mismatch between current user ownership and repository directory ownership.
  - *Resolution*: Verify the repository directory's filesystem ownership and ensure the source is trusted before adding it to Git's safe directories (`git config --global --add safe.directory <verified-path>`). Do not blindly add untrusted directories.

---

## Intended Lifecycle

```text
Intent → Context → Specification → Plan → Tasks → Implementation → Verification → Convergence → Evidence
```

Start with the desired outcome, inspect the project, and define success criteria before planning and implementing small tasks. Verification checks those criteria; convergence resolves gaps between the implementation and specification; evidence records what was checked and the results. Project-native checks remain authoritative, supplemented by the implemented read-only gates where applicable.

---

## Core Operating Model

### Constitution & Rules
- [Default Constitution](core/constitution/default.md): Ten core principles prioritizing surgical changes, simplicity, and evidence.
- [Coding Rule](core/rules/coding.md)
- [Architecture Rule](core/rules/architecture.md)
- [Testing Rule](core/rules/testing.md)
- [Git Rule](core/rules/git.md)
- [Documentation Rule](core/rules/docs.md)
- [Security Rule](core/rules/security.md)

### Lifecycle Skills
- [Context](core/skills/context.md): Read-only reality discovery.
- [Specify](core/skills/specify.md): Define WHAT and WHY.
- [Plan](core/skills/plan.md): Define HOW.
- [Tasks](core/skills/tasks.md): Executable task breakdown.
- [Implement](core/skills/implement.md): Execute approved scope.
- [Verify](core/skills/verify.md): Produce evidence against success criteria.
- [Converge](core/skills/converge.md): Reconcile implementation against specification.

### Workflows
- [Feature Workflow](core/workflows/feature.md): New capabilities or intentional behavior changes.
- [Bugfix Workflow](core/workflows/bugfix.md): Defects with reproduction, diagnosis, and regression verification.
- [Refactor Workflow](core/workflows/refactor.md): Structural improvements with baseline preservation.

### Enforcement & Gates
- [Gate Contract](gates/CONTRACT.md) & [Runner](gates/run.ps1): Deterministic read-only checks for Git whitespace errors and relative Markdown link integrity.
- [Verification Evidence Contract](docs/verification-evidence.md): Formal pass, fail, and blocked criteria.

---

## Separation of Concerns

- **Global Reusable System:** Shared principles, rules, skills, and workflows that apply across projects and agents (this repository).
- **Project-Specific Context:** A project's source, runtime behavior, architecture, constraints, and decisions (lives in `.ai-dev-system/PROJECT_CONTEXT.md`).
- **Temporary Task State:** Current intent, specification, plan, task list, and ephemeral verification logs.

---

## Links & Community

- **Documentation Index:** [docs/INDEX.md](docs/INDEX.md)
- **Releases & Changelog:** [GitHub Releases](https://github.com/truthrive/ai-dev-system/releases) | [CHANGELOG.md](CHANGELOG.md)
- **Issue Reporting:** [GitHub Issues](https://github.com/truthrive/ai-dev-system/issues)
- **License:** [LICENSE](LICENSE)
