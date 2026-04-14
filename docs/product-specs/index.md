# Product Specs Index

This folder is the canonical product-spec system of record for the `Citadel Siege` redesign.

## Active Specs

| Spec | Status | Purpose |
| --- | --- | --- |
| [core-game-loop.md](/C:/Users/min21/Desktop/flutter_grame/depense_game/docs/product-specs/core-game-loop.md) | active | Final player-facing session loop and siege rules |
| [campaign-structure.md](/C:/Users/min21/Desktop/flutter_grame/depense_game/docs/product-specs/campaign-structure.md) | active | 30-siege campaign structure, act pacing, and unlock flow |
| [economy-and-monetization.md](/C:/Users/min21/Desktop/flutter_grame/depense_game/docs/product-specs/economy-and-monetization.md) | active | Gold, Meta Gold, Siege Tokens, supply nodes, and reward rules |
| [meta-progression.md](/C:/Users/min21/Desktop/flutter_grame/depense_game/docs/product-specs/meta-progression.md) | active | Permanent growth model, act gates, and upgrade direction |
| [roster-and-buildables.md](/C:/Users/min21/Desktop/flutter_grame/depense_game/docs/product-specs/roster-and-buildables.md) | active | Front identity, enemy usage, counter mapping, and citadel damage rules |
| [map-production-plan.md](/C:/Users/min21/Desktop/flutter_grame/depense_game/docs/product-specs/map-production-plan.md) | active | Battlefield geometry, tile semantics, and authored siege examples |
| [new-user-onboarding.md](/C:/Users/min21/Desktop/flutter_grame/depense_game/docs/product-specs/new-user-onboarding.md) | active | First-session teaching flow for the multi-front format |
| [enemy-asset-pipeline.md](/C:/Users/min21/Desktop/flutter_grame/depense_game/docs/product-specs/enemy-asset-pipeline.md) | active | LPC-based directional enemy production and folder rules |
| [runtime-data-contracts.md](/C:/Users/min21/Desktop/flutter_grame/depense_game/docs/product-specs/runtime-data-contracts.md) | active | Concrete implementation contracts for siege, cycle, path, and rendering data |
| [web-verification-and-tooling.md](/C:/Users/min21/Desktop/flutter_grame/depense_game/docs/product-specs/web-verification-and-tooling.md) | active | Flutter Web plus Playwright validation workflow and QA harness rules |
| [first-playable-roadmap.md](/C:/Users/min21/Desktop/flutter_grame/depense_game/docs/product-specs/first-playable-roadmap.md) | active | Delivery milestones from spec lock to first multi-front playable |

## Related Generated Specs

These files are implementation-facing companions to the product specs:

| Generated Spec | Status | Purpose |
| --- | --- | --- |
| [ai-generated-assets-plan.md](/C:/Users/min21/Desktop/flutter_grame/depense_game/docs/generated/ai-generated-assets-plan.md) | active | Canonical AI and LPC asset-production plan for the first playable |

## Spec Order

Read in this order before implementation work:

1. [core-game-loop.md](/C:/Users/min21/Desktop/flutter_grame/depense_game/docs/product-specs/core-game-loop.md)
2. [campaign-structure.md](/C:/Users/min21/Desktop/flutter_grame/depense_game/docs/product-specs/campaign-structure.md)
3. [economy-and-monetization.md](/C:/Users/min21/Desktop/flutter_grame/depense_game/docs/product-specs/economy-and-monetization.md)
4. [roster-and-buildables.md](/C:/Users/min21/Desktop/flutter_grame/depense_game/docs/product-specs/roster-and-buildables.md)
5. [map-production-plan.md](/C:/Users/min21/Desktop/flutter_grame/depense_game/docs/product-specs/map-production-plan.md)
6. [runtime-data-contracts.md](/C:/Users/min21/Desktop/flutter_grame/depense_game/docs/product-specs/runtime-data-contracts.md)
7. [enemy-asset-pipeline.md](/C:/Users/min21/Desktop/flutter_grame/depense_game/docs/product-specs/enemy-asset-pipeline.md)
8. [new-user-onboarding.md](/C:/Users/min21/Desktop/flutter_grame/depense_game/docs/product-specs/new-user-onboarding.md)
9. [web-verification-and-tooling.md](/C:/Users/min21/Desktop/flutter_grame/depense_game/docs/product-specs/web-verification-and-tooling.md)
10. [first-playable-roadmap.md](/C:/Users/min21/Desktop/flutter_grame/depense_game/docs/product-specs/first-playable-roadmap.md)

## Rule

If a change affects player-facing behavior, combat readability, map authoring, economy pacing, enemy asset production, or the QA workflow, update the relevant spec in this folder before or with code.

Do not use `docs/game-concept-*` as the source of truth after this point. Those folders are historical exploration references only.
