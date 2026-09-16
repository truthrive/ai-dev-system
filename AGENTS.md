# Agent entrypoint

1. Read [docs/INDEX.md](docs/INDEX.md).
2. Read the [constitution](core/constitution/default.md).
3. Identify the task type (for example, documentation, feature, bug fix, or investigation).
4. Load only context, rules, skills, and workflows relevant to that task and available in the index.
5. Inspect current source and, where relevant, runtime behavior before relying on documentation.
6. Prefer the smallest necessary change.
7. Never modify unrelated files.
8. Verify against success criteria and provide evidence before claiming completion.

Use the index as the routing entrypoint as the system grows; unimplemented areas do not supply additional instructions.
