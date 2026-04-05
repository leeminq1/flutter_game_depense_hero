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
- 2026-04-04: Scout and Shield Infantry received a focused follow-up rerender with multi-agent silhouette review, improving the fast-ranged read and shield-frontline read without needing another full-roster export.
- 2026-04-04: Single-id LPC reruns now serialize correctly after fixing a PowerShell JSON array edge case discovered during the Shield Infantry A/B pass.
- 2026-04-04: Map production is now explicitly staged as a follow-up layer after current tower/building passes, with a dedicated plan for environment placements, runtime map rendering, and crest-stage authored layouts.
- 2026-04-04: Tower branch-specific `T2/T3` sprite assets now exist and runtime rendering prefers branch variants when a specialization has been chosen.
- 2026-04-04: Stage data now carries environment themes and decorative prop or landmark placements, and the battlefield renderer draws current environment sprites behind combat.
- 2026-04-04: Crest stages 5, 10, 15, 20, 25, and 30 now use hand-authored decoration layouts, and a second environment asset batch fills key missing props and landmarks for those scenes.
- 2026-04-04: Stage themes now tint path and build-slot visuals, and a crest-stage preview generator exists for quick scene-composition review outside the live runtime.
- 2026-04-04: The current environment manifest batch is now fully generated, including watch posts, checkpoint towers, cemetery statues, gate ruins, and the last reserved prop fillers.
- 2026-04-04: Runtime maps and crest-stage preview sheets now include lightweight biome-specific ground accents and path motifs, making each campaign bracket read more like a real place without sacrificing lane clarity.
- 2026-04-04: Map texture logic now reserves quiet buffers around slots and larger props, while giving spawn, core approach, and major bends a small amount of manual-looking emphasis for better battlefield orientation.
- 2026-04-04: Cached map texture planning now exists as a separate rendering-layer utility, so terrain marks are computed once per stage layout change instead of being regenerated inline during every render pass.
- 2026-04-05: Crest stages now support an extra bespoke terrain-story layer on top of the shared map texture planner, so milestone stages can carry stronger road wear, ritual residue, seep, siege abrasion, or infernal scar motifs without complicating regular-stage rendering.
- 2026-04-05: Crest stages now sit on top of the shared terrain planner with a separate bespoke overlay pass, allowing stage 5, 10, 15, 20, 25, and 30 to read more like authored capstones than only bracket variants.
- 2026-04-04: Runtime map texture sampling is now cached through `MapTexturePlanner`, reducing per-frame texture planning work and making the map pass easier to evolve without tangling combat rendering code.
- 2026-04-05: The first five stages now use a hand-tuned onboarding balance pass, and the battle screen now shows stage-specific tutorial guidance for the first-playable learning arc.
- 2026-04-05: A first-playable roadmap now exists as a product-spec artifact so upcoming work stays grouped by gameplay completion, content completion, stability, and public playable readiness.
- 2026-04-05: Stages 6-10 now use a more intentional first-midgame balance bridge, and the result overlay now explains win or loss state with clearer objective and retry guidance.
- 2026-04-05: Meta progression now uses a more intentional cost curve, first-clear and crest-stage bonus beats, and stronger upgrade-effect readouts.
- 2026-04-05: The app now has a real camp flow with a title/home screen, dedicated settings, help, and upgrade screens instead of dropping directly into battle.
- 2026-04-05: A cleanup audit now exists and the repo no longer keeps obvious scratch exports, temporary LPC dumps, or unused ad dependency wiring in the main app configuration.
- 2026-04-05: Stages 11-20 now use a hand-authored upper-midgame balance band with separate grave-march and cursed-chapel learning goals instead of only generic scaling.
- 2026-04-05: Camp-home and result overlays now surface next campaign gates and recommended meta investments so the player sees a clearer next action after both wins and losses.
- 2026-04-05: Stages 21-30 now use a hand-authored late-campaign arc with separate bastion-pressure and throne-march bands, plus a more intentional pre-boss lead-in.
- 2026-04-05: Late-campaign rewards and failure guidance now scale more intentionally so Warlock, Grave Guard, and boss-adjacent retries feel less opaque.

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
- Scout and Shield Infantry now have cleaner production-ready silhouettes, so the next LPC-heavy enemy art work can stay concentrated on higher-value caster and undead targets.
- One-enemy LPC experiments are now stable, which makes future art A/B testing much cheaper when comparing shield, helm, or body-type variants.
- The project now has a documented bridge from stage data and environment assets to real in-game map scenes, reducing ambiguity about whether map production is in scope.
- Tower specialization is now represented visually in runtime art, not only in combat numbers and UI text.
- Maps are no longer only abstract path lines; they now have the first runtime pass of environment identity using the existing prop and landmark asset batches.
- Crest stages now have stronger authored map identity instead of relying only on bracket-default decoration templates.
- Map review is now easier because crest-stage scene previews can be regenerated as a static sheet while iterating on environment placements.
- Environment production is no longer blocked by missing first-batch slots, so future work can focus on scene polish and bespoke stage composition.
- Biome identity now comes from ground language as well as props, which reduces the risk that maps feel like recolored variants of the same abstract board.
- Map texture density is now intentionally uneven, with gameplay-critical lanes and placement zones kept cleaner than decorative dead space.
- Terrain rendering is now easier to scale because cached map-texture planning separates generation logic from the main combat renderer.
- Crest-stage maps can now feel more authored than the rest of the bracket even when they still share the same core biome planner and prop set.
- First-playable UX now extends beyond onboarding into the result screen, reducing the chance that players fail without understanding the next correction to make.
- Crest-stage identity is now reinforced by both landmark layout and ground-overlay treatment, which helps those milestone stages read as bosses or checkpoints instead of only harder maps.
- Map texture rendering now has a clearer separation between planning and drawing, which lowers risk as future biome rules or crest-stage exceptions are added.
- The project now has a dedicated roadmap for moving from internal prototype quality toward a public first playable, with gameplay-complete work identified as the immediate focus.
