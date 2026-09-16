# Agent entrypoint

1. Read [docs/INDEX.md](docs/INDEX.md).
2. Read the [constitution](core/constitution/default.md).
3. Inspect the current branch, working tree, source, and relevant runtime behavior before relying on documentation.
4. Route new behavior to the [feature workflow](core/workflows/feature.md), defects to the [bugfix workflow](core/workflows/bugfix.md), and behavior-preserving structural work to the [refactor workflow](core/workflows/refactor.md).
5. For documentation or investigation, load only the relevant [rules and skills](docs/INDEX.md); use the read-only Context skill when project reality is uncertain.
6. Load only the selected workflow and the rules and skills it requires.
7. Prefer the smallest necessary change and never modify unrelated files.
8. Verify against success criteria, then converge the result with evidence before claiming completion.

Unimplemented areas listed in the index do not supply additional instructions.
