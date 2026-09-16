# Agent entrypoint

1. Read [docs/INDEX.md](docs/INDEX.md).
2. Read the [constitution](core/constitution/default.md).
3. Inspect the current branch, working tree, source, and relevant runtime behavior before relying on documentation.
4. For first-time project adoption, use the preview-first [onboarding procedure](docs/onboarding.md) before proposing changes.
5. Route new behavior to the [feature workflow](core/workflows/feature.md), defects to the [bugfix workflow](core/workflows/bugfix.md), and behavior-preserving structural work to the [refactor workflow](core/workflows/refactor.md).
6. For documentation or investigation, load only the relevant [rules and skills](docs/INDEX.md); use the read-only Context skill when project reality is uncertain.
7. Load only the selected workflow and the rules and skills it requires. Prefer the smallest necessary change and never modify unrelated files.
8. Verify against success criteria using project-native checks and applicable [gates](gates/CONTRACT.md).
9. Record results under the [evidence contract](docs/verification-evidence.md), then converge before claiming completion.

Unimplemented areas listed in the index do not supply additional instructions.
