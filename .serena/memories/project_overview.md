# Project Overview

- Purpose: Flutter + Flame fantasy fortress/tower-defense prototype (`Citadel Siege`) focused on performant 2D mobile-first gameplay.
- Stack: Dart/Flutter, Flame, flame_audio, Isar for local persistence, Flutter tests.
- Architecture: Flutter owns app shell/screens/overlays/persistence surfaces; Flame owns real-time map, waves, movement, targeting, combat, entities, and rendering.
- Key folders: `lib/app` for UI/screens/theme, `lib/game` for Flame runtime and models, `lib/data` for campaign/progression/persistence, `assets/sprites` and `assets/audio` for content, `docs/product-specs` and `docs/design-docs` for gameplay/system records.
- Current gameplay direction: multi-front `Citadel Siege`, enemies route from front-authored entries toward a citadel, player builds 1x1 barriers/towers during prep/recovery, towers do not block movement, barriers do, hero guards near an assigned defense position.