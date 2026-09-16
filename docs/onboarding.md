# Project onboarding

Onboarding discovers project reality before proposing one additive context file. It does not install AI Dev System, change project instructions, or infer stack-specific commands.

## Project types

- **New:** capture intent, intended boundaries, and initial success criteria before implementation. A Git repository is optional.
- **Active:** preserve current behavior and conventions; inspect established instructions, checks, documentation, and working-tree state first.
- **Legacy:** establish behavior from source and runtime evidence, record documentation drift and risk, and avoid modernization outside an approved task.

## Procedure

1. Preview discovery from the AI Dev System repository:

   ```powershell
   pwsh -NoProfile -File onboarding/onboard.ps1 -ProjectRoot <path> -ProjectType New|Active|Legacy
   ```

2. Review detected instructions, context, conventions, check definitions, documentation, Git root, and uncommitted work.
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

Exit code `0` means preview or apply completed, `1` means an unexpected execution failure, and `2` means apply was blocked without writing the context file.
