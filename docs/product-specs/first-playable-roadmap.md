# First Playable Roadmap

## Objective

Ship the first end-to-end `Citadel Siege` playable without overcommitting to late-stage complexity before the core loop is proven.

## Milestone 0: Spec Lock

Required outcome:

- product specs in this folder are the accepted source of truth
- the team agrees to `campaign-first`, `authored multi-front`, `no baseline A* mazing`

## Milestone 1: Runtime Data Bridge

Required work:

- add `SpawnDirection`
- add `AssaultCycleDefinition`
- add `pathsByDirection`
- add citadel-aware targeting
- preserve existing tower and enemy definition reuse

Exit criteria:

- one siege can resolve with north and west fronts

## Milestone 2: Battlefield Conversion

Required work:

- convert the battlefield to `14 x 14`
- add central `3 x 3` citadel
- add supply node tiles
- add front telegraphs

Exit criteria:

- Siege 1-3 run on the new battlefield

## Milestone 3: Art And Rendering Bridge

Required work:

- runtime supports direction-aware enemy sprite lookup
- east mirroring works
- north and south pilot exports are integrated
- citadel landmark renders correctly

Exit criteria:

- at least one enemy family renders correctly in all directions

## Milestone 4: Act 1 Playable

Required work:

- Siege 1-5 authored
- onboarding prompts implemented
- recovery windows and rewards functioning
- persistence updated for new result flow
- Command Charges explicitly out of scope for this milestone

Exit criteria:

- a full Act 1 can be played and cleared
- a failed run still returns valid persistent progress
- the run is playable without Command Charges

## Milestone 5: Web QA Harness

Required work:

- make Flutter Web run cleanly through `web-server`
- add a web-safe persistence path or debug-only in-memory store for browser QA
- add a QA overlay path for automation
- expose readable state text for cycle, fronts, gold, citadel HP, and selected buildable
- capture the required portrait-phone and portrait-tablet screenshots

Exit criteria:

- Playwright can load the app and drive the portrait smoke flow
- required viewport checks pass at `360 x 800`, `412 x 915`, `768 x 1024`, and `834 x 1194`
- landscape mode is blocked by the portrait-only guard

## Milestone 6: Tactical Layer And Campaign Expansion

Required work:

- Command Charges implemented and tuned
- Acts 2-6 authored
- support, revive, ward, and boss pressure tuned
- late acts stress-tested for readability

Exit criteria:

- Siege 30 final breach completes

## Required Verification

Before calling the first playable ready, verify:

- `flutter analyze` passes
- Flutter Web launches on `web-server`
- Playwright can drive the app for smoke flows
- at least one automated or semi-automated screenshot review exists for key states
- required portrait viewport checks pass at `360 x 800` and `412 x 915`
- required tablet portrait viewport checks pass at `768 x 1024` and `834 x 1194`
- portrait HUD, battle viewport, and build controls remain readable and tappable
- landscape mode is blocked by the portrait-only guard
