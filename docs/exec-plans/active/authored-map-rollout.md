# Authored Map Rollout

## Objective

Create a sustainable workflow for building the campaign as `hand-authored siege maps` instead of relying on broad random obstacle generation.

## Why This Exists

The game is strongest when players can:

- read the fortress layout
- understand why a route is dangerous
- improve through better positioning on repeat attempts

That requires authored geometry, authored front pressure, and deliberate obstacle language.

## Deliverables

- map authoring rules in `docs/design-docs/map-authoring/`
- one reviewed map bible for `Act 1`
- a stage card template we can reuse for all 30 sieges
- a later implementation pass that converts approved cards into runtime data

## Rollout Order

1. lock map rules and collaboration workflow
2. hand-author `Sieges 1-5`
3. validate fun and readability in runtime
4. hand-author `Sieges 6-10`
5. continue by act, not by isolated stage

## Current Decisions

- 2026-04-19: campaign maps should prefer authored layouts over unrestricted random obstacle generation
- 2026-04-19: citadel position may vary by approved pattern instead of staying permanently centered
- 2026-04-19: the first concrete authored-map pass should focus on `Act 1`
- 2026-04-19: obstacle clusters must have gameplay jobs, not only visual flavor

## Risks

- too much castle-position variance too early could hurt readability
- fully free citadel placement could break camera and HUD assumptions
- overcomplicated obstacle shapes could feel unfair on mobile screens
- adding tower-damaging enemies too broadly could make runs feel noisy instead of tactical

## Working Rule

Do not convert a draft stage into code until its stage card locks:

- citadel pattern
- cycle front order
- obstacle roles
- fallback pocket
- intended kill zone
