# Project onboarding

Onboarding discovers project reality before proposing one additive context file. It does not install AI Dev System, change project instructions, or infer stack-specific commands.

## Project types

- **New:** capture intent, intended boundaries, and initial success criteria before implementation. A Git repository is optional.
- **Active:** preserve current behavior and conventions; inspect established instructions, checks, documentation, and working-tree state first.
- **Legacy:** establish behavior from source and runtime evidence, record documentation drift and risk, and avoid modernization outside an approved task.

## Procedure

1. Preview discovery from the AI Dev System repository:

   ```powershell
   pwsh -NoProfile -File onboarding/onboard.ps1 -ProjectRoot <path> -ProjectType Active
   ```

2. Choose `New`, `Active`, or `Legacy`. Review detected instructions, context, conventions, check candidates, test setup files, declarations, documentation, Git root, and uncommitted work. Candidates are paths, not verified commands. Package scripts and lockfiles are declarations, not verified commands or prerequisites.
3. Resolve any blocker. For active and legacy projects, the target must be the root of a clean Git work tree. Any existing project-context file requires a manual decision.
4. Create the context file by repeating the command with `-Apply`.
5. Review the newly created `.ai-dev-system/PROJECT_CONTEXT.md`, replace unconfirmed statements only with evidence, and use the project's normal review process before committing it.
6. Run project-native checks and any applicable [AI Dev System gates](../gates/CONTRACT.md). Record results under the [verification and evidence contract](verification-evidence.md).

## Safety behavior

- Preview is read-only and is the default.
- Apply creates only `.ai-dev-system/PROJECT_CONTEXT.md` and its parent directory when missing.
- Existing instruction or documentation files are discovered and reported but never changed.
- Apply refuses to run when the context target or another recognized project-context file already exists.
- Apply refuses dirty Git work trees and project paths that are not the detected Git root.
- Apply refuses active or legacy projects when Git state cannot be verified.
- The tool performs no dependency installation, network access, command inference, or project check execution.

Git access failures return `BLOCKED` with the original diagnostic and stop discovery, including preview. Ownership protections and Git configuration are never altered. Exit code `0` means preview or apply completed, `1` means an unexpected execution failure, and `2` means Git access or apply was blocked.

Discovery excludes directories named `.git`, `node_modules`, `vendor`, `dist`, `build`, `coverage`, `.astro`, `.next`, `.nuxt`, `.cache`, `__pycache__`, `.venv`, `venv`, `bin`, and `obj`, and does not follow symbolic links. Git projects otherwise use tracked and non-ignored files. Ignored instructions are probed only at `AGENTS.md`, `CLAUDE.md`, `.cursorrules`, `.github/copilot-instructions.md`, and immediate skill directories under `.agent/skills`, `.agents/skills`, and `.codex/skills` for `SKILL.md`.

When a non-Git target has immediate child Git roots, onboarding reports them separately, excludes their contents from parent discovery, and blocks apply until one root is explicitly selected. Test setup and test configuration files are reported separately from check entrypoints.

Recognized context includes `PROJECT_CONTEXT.md`, `project-context.md`, `WEBSITE_CONTEXT_PACK.md`, and `docs/context.md`. Existing recognized context blocks automatic creation. Other naming conventions still need manual review. JSON retains `discovery.checks` as a compatibility alias for `checkCandidates`; `verifiedCommands` and `prerequisites` are empty until independently verified. Evidence separates observed file/Git facts, unverified documentation sources, unknowns, and source references.
