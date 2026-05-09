# AGENTS.md

This repository uses an agent-first documentation harness.

Start here, then progressively load only the docs needed for the task.

## Mission

Build a performant 2D tower defense game in Flutter + Flame with a content pipeline that stays maintainable as the game grows.

Current working assumptions:
- Platform priority: Android first, desktop-friendly dev workflow.
- Rendering style: 2D stylized assets with reusable sprite sheets.
- Design goal: short sessions, readable combat, scalable content production.

## Load Order

1. Read [ARCHITECTURE.md](/C:/Users/min21/Desktop/flutter_grame/depense_game/ARCHITECTURE.md) for system boundaries.
2. Read [docs/product-specs/index.md](/C:/Users/min21/Desktop/flutter_grame/depense_game/docs/product-specs/index.md) for gameplay intent.
3. Read [docs/design-docs/index.md](/C:/Users/min21/Desktop/flutter_grame/depense_game/docs/design-docs/index.md) for design beliefs and content pipeline.
4. Read [docs/design-docs/audio-architecture.md](/C:/Users/min21/Desktop/flutter_grame/depense_game/docs/design-docs/audio-architecture.md) before touching sound, music, or ad-related lifecycle code.
5. Read [docs/exec-plans/active/initial-defense-game-foundation.md](/C:/Users/min21/Desktop/flutter_grame/depense_game/docs/exec-plans/active/initial-defense-game-foundation.md) before implementing larger changes.
6. Read [QUALITY_SCORE.md](/C:/Users/min21/Desktop/flutter_grame/depense_game/QUALITY_SCORE.md), [RELIABILITY.md](/C:/Users/min21/Desktop/flutter_grame/depense_game/RELIABILITY.md), and [SECURITY.md](/C:/Users/min21/Desktop/flutter_grame/depense_game/SECURITY.md) before shipping.

## Working Rules

- Keep this file short. Do not turn it into the knowledge base.
- Treat `docs/` as the system of record.
- Prefer updating an existing spec or plan over inventing undocumented behavior.
- Prefer Serena's project and symbolic tools for codebase understanding.
- Do not look for `graphify-out/` as a default preflight step.
- Do not use `graphify-project-awareness` or any graphify skill unless the user explicitly asks for graphify by name.
- For feature work, record intent first, then code, then verification notes.
- For larger tasks, update the active exec plan with progress, decisions, and risks.
- If gameplay and performance goals conflict, protect frame pacing first.
- If asset generation is involved, document prompt, source, license, and export format.
- Avoid loading every doc into context. Follow the indexes.

## Game-Specific Priorities

- Stable 60 FPS on target mobile hardware.
- Deterministic-enough combat outcomes for debugging and balancing.
- Clean separation between game simulation, Flutter overlays, and content data.
- Data-driven towers, enemies, waves, and upgrades.
- Cheap-to-produce art pipeline that can scale with AI-assisted ideation and human cleanup.

## Where To Put New Knowledge

- Combat and feel: `docs/design-docs/`
- User-facing feature specs: `docs/product-specs/`
- Active implementation plans: `docs/exec-plans/active/`
- Completed work logs: `docs/exec-plans/completed/`
- Generated artifacts and schemas: `docs/generated/`
- External references and distilled notes: `docs/references/`

## Missing Context

The exact fantasy/theme, lane shape, and monetization model are not fixed yet.
When those decisions are made, update:
- [DESIGN.md](/C:/Users/min21/Desktop/flutter_grame/depense_game/DESIGN.md)
- [PRODUCT_SENSE.md](/C:/Users/min21/Desktop/flutter_grame/depense_game/PRODUCT_SENSE.md)
- [docs/product-specs/core-game-loop.md](/C:/Users/min21/Desktop/flutter_grame/depense_game/docs/product-specs/core-game-loop.md)

