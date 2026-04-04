# Plans

This repository uses versioned execution plans for work that spans multiple files or decisions.

## Rules

- Put active plans in `docs/exec-plans/active/`.
- Move finished plans to `docs/exec-plans/completed/`.
- Log decisions when they change implementation shape, scope, or risk.
- Track blocked items and unknowns explicitly.

## Plan Types

- Lightweight plan: one small feature or refactor.
- Execution plan: multi-step systems work with dependencies and verification.
- Debt entry: known issue tracked in `docs/exec-plans/tech-debt-tracker.md`.
