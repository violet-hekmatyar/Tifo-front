# AGENTS.md

Global working defaults for this repository, mirrored from the Codex global setup
(`D:\CODEX_SKILL\GLOBAL_AGENTS_SNIPPET.md` → `C:\Users\hekmatyar\.codex\AGENTS.md`).
The 13 user-level skills from `D:\CODEX_SKILL` are available to the agent in every
session via the shared `C:\Users\hekmatyar\.agents\skills` directory.

## Efficient development defaults

- Prefer direct implementation over long planning when the task is already clear.
- Read only files directly relevant to the requested change. Expand outward only when a dependency or call path requires it.
- Do not scan the whole repository, enumerate all TODOs, or reread large documents unless the task explicitly requires a broad audit.
- Reuse existing project conventions, components, services, models, and utilities before creating new abstractions.
- Keep changes scoped. Do not perform unrelated refactors, dependency upgrades, migrations, formatting churn, or architecture changes.
- During ordinary implementation, use the smallest meaningful validation for the changed behavior. Do not run full test/lint/build suites unless requested, required by repository instructions, or justified by the risk of the change.
- For bug fixes, identify the root cause and make the smallest correct fix. Verify the failing scenario directly.
- Treat existing API/schema/contracts as authoritative when integrating systems. Do not invent endpoints, fields, or protocol changes.
- Ask a clarifying question only when ambiguity materially affects correctness, safety, or destructive behavior; otherwise infer from local project patterns and proceed.
- Keep final reports concise: changed files, completed behavior, validation performed, and any blocker/remaining issue.
- Use subagents only when work is genuinely parallel or would otherwise pollute the main context. Avoid parallel agents for small tasks because they consume more tokens.
- Do not invoke broad brainstorming, full TDD, or exhaustive review workflows by default when a narrower workflow satisfies the request.
- Explicit user instructions in the conversation override these defaults.
