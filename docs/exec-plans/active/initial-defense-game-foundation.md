# Initial Defense Game Foundation

## Objective

Create the first playable vertical slice and the documentation discipline needed to scale it with agents.

## Scope

- Project bootstrap for Flutter + Flame
- Core battlefield loop
- First three towers
- First four enemy archetypes
- Wave authoring format
- Basic onboarding and upgrade UI
- Local persistence for account progress and stage history
- Monetization-safe UX boundaries for future ads
- Asset pipeline and balancing workflow

## Milestones

1. Bootstrap
   - Create Flutter project and add Flame dependencies.
   - Set up package boundaries, placeholder scenes, and audio service boundaries.
2. Combat slice
   - One map, placement flow, enemy pathing, attacks, win/loss state, and audio event hooks.
3. Content slice
   - Author three distinct towers and four enemies from shared definitions.
4. UX slice
   - Add onboarding, pause, results, and upgrade overlays.
5. Production slice
   - Add profiling, validation, asset import conventions, and persistence migration rules.

## Decision Log

- 2026-04-02: Documentation harness created before gameplay code so future agent work has stable context.
- 2026-04-02: Prioritized data-driven content over bespoke single-level scripting.
- 2026-04-02: Chosen visual direction is LPC-compatible fantasy with modular humanoid factions.
- 2026-04-02: Stage structure is fixed-path tower defense with changing maps and escalating stage content.
- 2026-04-02: Meta progression will prioritize permanent growth stored locally on-device.
- 2026-04-02: Audio is part of the first architecture pass, not a late polish layer.
- 2026-04-02: Flutter + Flame prototype scaffold now exists in code with local Isar persistence, stage selection, stage completion rewards, and in-run upgrade/sell interactions.
- 2026-04-02: Voice result lines were removed in favor of non-voice jingles.
- 2026-04-02: Tower-specific combat abilities and enemy-specific combat traits are now part of the runtime simulation.
- 2026-04-02: A persistent meta upgrade tree now exists and applies to future stage loads.
- 2026-04-02: Tower specialization branches and enemy ability visual feedback are now part of the prototype combat loop.
- 2026-04-02: Stage goals, star rules, and unlock dependencies are now part of campaign progression.
- 2026-04-02: Meta-gated buildable unlocks and lightweight projectile / pulse combat visuals are now part of the runtime loop.
- 2026-04-02: Late-campaign enemy roster now includes Grave Guard and Warlock behaviors with summoning and ward support.
- 2026-04-02: Stage 30 now has a dedicated Bastion Overlord boss wave with phase transitions and escort summons.
- 2026-04-02: LPC-ready sprite slot manifests and a visual catalog now exist so placeholder rendering can be swapped to imported art later.
- 2026-04-02: Runtime sprite loading now checks for real PNG assets and falls back safely when a slot is still empty.
- 2026-04-04: Stage art bible, environment asset matrix, and explicit size rules now define how towers, enemies, props, and landmarks should scale and evolve across the 30-stage campaign.
- 2026-04-04: Environment sprite slot manifests now reserve reusable props and landmark paths before map set dressing begins.
- 2026-04-04: Tower rendering scale is now explicitly larger than enemy rendering scale through per-asset visual definitions.
- 2026-04-04: Shared environment props and crest-stage landmark sprite batches now exist as actual PNG assets, not only reserved slots.
- 2026-04-04: First-pass tower sprites were upgraded into more building-like battlefield anchors with clearer roof, base, and role silhouettes.
- 2026-04-04: Detailed enemy and defense roster bibles now lock role intent, counter mapping, silhouette rules, and upgrade fantasy before more art and balance passes.
- 2026-04-04: Tower upgrade-tier sprite assets now exist for every buildable and are selected by runtime tower level.
- 2026-04-04: Guard Barracks now has tiered defender-side sprites rendered in combat as a safe visual-only summon representation.
- 2026-04-04: Enemy sprites received a multi-agent-reviewed second-pass silhouette polish, while a full LPC re-export pass remains blocked by a Windows command-line length limit in the current automation script.
- 2026-04-04: Guard Barracks now has attached defender sprite variants, and enemy sprites received a second-pass silhouette polish informed by multi-agent review.
- 2026-04-04: Guard Barracks now has attached defender sprite assets and branch-aware visual variants for the lightweight summoned-guard fantasy.
- 2026-04-04: Enemy sprite set received a multi-agent review and a second-pass silhouette polish pass, with next LPC-heavy targets clearly documented.
- 2026-04-04: Tower rendering now supports tier-specific sprite files so level 1, 2, and 3 towers can show distinct visuals at runtime.
- 2026-04-04: The LPC enemy export pipeline now runs through a dedicated Node + Playwright tool, resolving the earlier Windows command-line length limit and restoring full batch re-export capability.
- 2026-04-04: Targeted LPC rerenders now work for selected enemy ids, and Cult Adept, Grave Guard, and Warlock received the first focused third-pass rerender after the pipeline fix.

## Risks

- Choosing a camera or map format too early could lock in poor content workflows.
- Over-scoping the first vertical slice could delay fun and profiling.
- Asset experimentation could outpace naming and export discipline.
- Reward, save, and ad boundaries could create duplication bugs if not modeled transactionally.
- Large-scale wave combat may produce too many overlapping SFX unless event categories are throttled and pooled.

## Exit Criteria

- One complete run is playable end to end.
- A new enemy can be added mostly through data and assets.
- Major runtime systems have at least one profiling checkpoint.

## Current Status

- A prototype stage can now be played with real-time tower placement during waves.
- Campaign progression scaffolding exists for 30 stages with unlock and reward persistence.
- Audio settings persist locally and combat SFX are integrated through the central audio service.
- Rewarded bonus flow is scaffolded as a safe post-stage reward claim, pending real ad SDK hookup.
- Meta progression can now spend persistent currency on stage-wide and tower-specific upgrades.
- Ballista and Emberkeep are now implemented as unlockable buildables tied to meta progression.
- Combat readability now includes simple projectile, beam, pulse, impact, and burn-state visuals without heavy FX overhead.
- Stages 18-30 now escalate with control-resistant undead tanks and support casters that summon new enemies.
- Stage 30 now functions as a real campaign capstone rather than only a stat-scaled final wave.
- Runtime art paths are now reserved for towers, enemies, and the final boss even before final sprites are imported.
- Stage progression now has an environment production plan for frontier roads, grave fields, cursed chapel zones, bastion approaches, and final throne-march stages.
- Tower sprites now exist as first-pass static battlefield structures, and their on-screen scale rules are separated from enemy sprite scale.
- Reusable environment props and six major landmark structures now exist as first-pass sprites for future map set dressing and biome previews.
- Tower art now has a stronger second-pass silhouette language, making core buildables read more like placeable structures than flat icons.
- Enemy families and player buildables now have dedicated detailed design references beyond the high-level roster summary.
- Every tower now has `T1`, `T2`, and `T3` sprite variants available for runtime level-based rendering.
- Guard Barracks now reads more clearly as a defender-summoning structure through attached defender sprites that scale with tower tier.
- Enemy sprites now have clearer support, tank, and boss reads after the local polish pass documented in the LPC asset notes.
- Guard Barracks now displays defender visuals tied to level and specialization, improving lane-control readability without changing simulation rules.
- Enemy art now has a documented second-pass polish layer on top of the LPC base so weak silhouettes are less likely to persist into later content work.
- Guard Barracks now displays visible defender units tied to level and branch, even though combat still uses the existing tower simulation.
- Enemy art now has documented review priorities and a second-pass polish baseline rather than only first-export LPC sprites.
- Every current tower now has generated T1/T2/T3 sprite assets, and the runtime selects the matching tier sprite when available.
- LPC enemy rerendering is no longer blocked by the old inline CLI payload limit, so future art passes can iterate from the generator again instead of only local overlays.
- High-priority caster and undead targets can now be rerendered independently without forcing a whole-roster export, making iterative art passes much faster.
