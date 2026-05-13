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
- 2026-04-08: LPC enemy export now emits `walk_02` and `walk_03` companion frames through the same 64x64 crop pipeline, so enemy walk cycles can be generated without mixing in mismatched external PNG sizes.
- 2026-04-08: LPC enemy base PNGs now also come from the split animation ZIP at `standard/walk/down/5.png`, making base and walk frames come from one canonical source instead of mixing in idle-preview captures.
- 2026-04-08: The live enemy roster now includes six additional LPC-derived units: Banner Captain, Wolf Scout, Bone Archer, Plague Bearer, Hex Sniper, and Bastion Priest.
- 2026-04-08: Campaign roster profiles now use array-backed pools for common, support, elite, and boss kinds so wave sourcing can grow without adding more fixed biome slots.
- 2026-04-08: Campaign stages now support explicit `tileGrid` and `pathSequence` data, and the default 30-stage sample campaign uses a centered `8 x 14` tile board instead of distance-only path clearance for build legality.
- 2026-04-08: Runtime map rendering can now draw Kenney grass/path tiles from grid data, including neighbor-based path trim overlays and direct tile-center enemy waypoint conversion.
- 2026-04-08: The battle screen layout now separates the top HUD, gameplay viewport, and bottom build bar so Flame content no longer renders underneath combat UI chrome.
- 2026-04-08: Path tiles now resolve as semantic straight, turn, and cap variants from renamed Kenney road assets instead of compositing multiple opaque road overlays at render time.
- 2026-04-08: Spawned enemies are now placed on the first path point immediately, reducing the risk that early spawns are hidden under UI or start at a stale zero position.
- 2026-04-14: A concept-exploration folder now exists at `docs/game-concept-gpt/` to evaluate a pivot from fixed-path stage defense toward multi-front fortress defense with all-direction enemy approaches, without rewriting the official product specs yet.
- 2026-04-14: `docs/product-specs/` has now been fully rewritten around the `Citadel Siege` direction, including multi-front siege rules, runtime data contracts, LPC enemy pipeline requirements, and Flutter Web plus Playwright validation workflow.
- 2026-04-14: Product specs were corrected to unify `Siege` terminology, restore scaling formulas, lock citadel damage values, clarify `Meta Gold` versus `Siege Tokens`, and move Web QA after gameplay readiness in the milestone order.
- 2026-04-14: A generated asset-production brief now exists at `docs/generated/ai-generated-assets-plan.md`, defining blocker art, LPC folder structure, prompt text, batch priority, and validation rules for the first playable.
- 2026-04-14: Progress-store bootstrapping now routes web builds to an in-memory store through a shared abstraction, removing the Isar-specific web compile blockers for both JS and Wasm builds.
- 2026-04-14: Enemy asset tooling and runtime lookup now support the new per-enemy folder structure under `assets/sprites/enemies/{enemy_id}/...`, while preserving flat-file fallback during migration.
- 2026-04-14: Web verification is now executable instead of speculative: local `flutter build web`, `flutter build web --wasm`, and Playwright portrait screenshot captures all succeeded after the persistence abstraction change.
- 2026-04-14: The first `Citadel Siege` code bridge is now in runtime data itself: Act 1 sieges ship authored `14x14` siege grids, `pathsByDirection`, `supplyNodeCells`, `assaultCycles`, `direction`-aware spawn groups, and spec-aligned `citadelDamage` plus scaling formulas while still preserving the legacy wave bridge for the existing combat loop.
- 2026-04-15: Battlefield conversion is now underway in runtime logic: enemies can spawn with per-front route assignment, movement and targeting can resolve against citadel distance instead of one global lane progress, supply-node-only Coin Mill placement is enforced, and the renderer can now draw citadel, supply-node, and front-telegraph assets while preserving web build compatibility.
- 2026-04-15: Portrait battle HUD cleanup continued: the top HUD now compacts on narrow phone widths, the battle screen exposes front status plus recovery state more clearly, and the legacy right-side wave CTA no longer competes with the left-side cycle CTA on compact layouts.
- 2026-04-15: Spawn cues now reflect active or next fronts instead of always implying a single lane, which makes authored `Citadel Siege` fronts read correctly during prep, assault, and recovery.
- 2026-04-15: Flutter Web portrait QA was rerun through Playwright on the rebuilt static web bundle. Verified flows now include splash, menu, camp, siege entry, cycle start, assault-state HUD, recovery-state HUD, tablet portrait scaling, and the portrait-only landscape guard.
- 2026-04-15: The splash/title screen now has a dedicated portrait-safe variant so `360x800` no longer crops the `DEPENSE` title, and the battlefield build summary plus default battle guidance no longer ship with garbled placeholder text.
- 2026-04-16: Citadel-siege follow-up fixes now restore authored front routes and on-board telegraphs, re-lock tower placement to valid buildable tiles only, allow immediate manual cycle starts during recovery, and normalize the outlier landmark and supply-node sprite sizes back to the environment asset set.
- 2026-04-16: Act 1 siege runtime now follows the rebuilt `full-map 1x1 placement + explicit obstacle` model: Coin Mill no longer depends on supply-node-only placement in the playable, the citadel is rendered as a `1x1` center anchor, visible environment obstacles now own build blocking and enemy detours, and obstacle density drops from stage 1 through stage 5 instead of relying on generic blocked-tile overlays.
- 2026-04-19: A dedicated authored-map workflow now exists under `docs/design-docs/map-authoring/`, establishing the plan to handcraft the 30-stage campaign by act instead of leaning on unrestricted random obstacle generation.
- 2026-04-21: Stage 6 now starts the quadrant-based castle-position arc with an authored `[7,5]` citadel, and campaign map generation can place the citadel from stage data instead of assuming the fixed `[6,6]` center.
- 2026-04-21: Stage 7-10 are now planned as authored maps instead of fallback layouts, combat SFX are budgeted through a per-frame queue, monsters can damage towers, and the first stage-local hero purchase model is being introduced.
- 2026-04-22: Stage 11 now starts the second-quadrant authored map arc with a `[4,5]` citadel, and authored citadel stages now reuse the central starting-gold and base-health balancing helpers instead of hardcoded `380/40` values.
- 2026-04-22: Stage 11 was shifted further into the second quadrant at `[4,5]`, and Stage 12-15 now complete the authored second-quadrant arc through `[5,4]`, `[4,4]`, `[3,4]`, and `[3,3]`.
- 2026-04-22: Gameplay balance pass removed starting-gold bracket jumps, raised enemy HP scaling, made Stage 2 a 4-Cycle stage, extended authored citadel maps through Stage 30, strengthened tower destruction pressure, and gave heroes distinct lightweight abilities tied to existing meta tracks.
- 2026-04-25: Stage 16-20 now use explicit third-quadrant authored layouts and custom undead pressure cycles instead of placeholder direct routes, and the map-authoring docs now describe the lower-left campaign policy in Korean.
- 2026-04-25: Combat HUD and audio stabilization now treat the enemy counter as "remaining enemies in the current Cycle", keep Cycle-to-Cycle progression on manual start, route short combat SFX through an Android low-latency backend, and reduce runtime HUD churn through dirtied-session comparison instead of broad post-frame syncing.
- 2026-04-25: Cycle stall protection now force-resolves invisible or invalid enemies near the citadel, so the final visible breach does not leave Stage 1 Cycle 3 stuck in an endless "pause" state.
- 2026-04-25: Remaining-enemy HUD now reconciles from runtime state (`alive + pending spawns`) instead of trusting only event-style increments and decrements, and empty-field late spawns are accelerated to avoid Stage 1 Cycle 3 appearing frozen between the last groups.
- 2026-04-25: Runtime front spawns now enter from the edge aligned to their first route cell instead of a fully randomized edge anchor, preventing single-enemy late groups from lingering offscreen and blocking Cycle completion.
- 2026-04-25: Cycle reconciliation now treats any enemy with `HP <= 0` as terminal even if an earlier defeat path failed to remove it immediately, preventing a hidden dead enemy from leaving the HUD at `1` after all visible threats are gone.
- 2026-04-25: Stage clear/fail resolution now flushes pending session state before the terminal-state early return and marks status text dirty immediately, so Flutter overlays switch to the result popup as soon as the citadel falls or the last Cycle resolves.
- 2026-04-26: Citadel Siege v2 pivots the campaign from authored blocking obstacles to player-built fortress planning: stages now use quadrant-arc citadel positions, each front exposes three spawn entries, barriers block and can be breached, live assault building is disabled, and heroes are chosen before a run then summoned once per stage.
- 2026-04-26: Follow-up tuning moved Stage 1's citadel to the lower-left corner arc, raised starting Gold for wall planning, lowered early wall/tower costs, split the build bar into Tower/Wall/Hero tabs, and changed heroes to free auto-placement plus one recovery-window revive.
- 2026-04-27: Citadel Siege QA follow-up localizes barrier selection and breach messaging, shows placement tiles for the Wall tab, keeps all three per-front routes open from Stage 1, and tightens early-stage decoration spacing so Stage 3's citadel remains readable.
- 2026-04-29: Runtime maps now render visible muted-brown road tiles from authored route data, and each run now offers `1 of 3` temporary siege modifiers before Cycle 1 and after recovery windows to add replayable tower, barrier, and hero build variation without changing route or stage rules.
- 2026-04-30: Siege offers now require an explicit dice roll before showing the 3 choices, offer copy is Korean-first, path readability uses subtle trampled-grass/dust marks instead of heavy brown road fills, building placement no longer auto-opens the action popup, and combat now has lightweight hit/death feedback with floating damage and reward text.
- 2026-04-30: Battle UI terminology is now `WAVE` / `STAGE`, the dice offer appears once at STAGE start instead of before every wave, and enemy movement speed is globally doubled while preserving per-enemy speed differences.
- 2026-05-01: Gameplay direction narrowed around fortress-design payoff: hero defense position is locked during active Waves, design-card dice appears on a 3-Stage cadence starting at Stage 4, early build cells should be authored near the citadel/routes instead of exposing the whole grass field, and fast-enemy rerouting is reserved for Stage 4+.
- 2026-05-09: Gameplay readability pass now paints muted brown route marks only on actual enemy route cells, auto-opens the Stage 1 briefing with a compact tactical diagram, lets enemies treat a forward hero as a blocker target, lowers barrier costs to early-fortress validation values, removes the unused repair metric from barrier cards, and doubles Wave-clear recovery gold.
- 2026-05-09: Playtest follow-up strengthened road readability from subtle dirt marks into full brown road tiles, aligned enemy movement to authored visible road cells instead of free-grid shortest paths, and replaced the Stage briefing diagram with a fixed Stage 1 tactical preview image.
- 2026-05-09: Campaign content review now temporarily unlocks all 30 stages through `kUnlockAllCampaignStagesForDevelopment`; this is documented in `docs/product-specs/campaign-structure.md` and must be set back to `false` before public release so authored unlock progression returns.
- 2026-05-11: Firebase Hosting project `pixel-guard-wave-min21` now serves the PIXEL GUARD:WAVE developer site, privacy policy, and root `app-ads.txt` for AdMob seller authorization.
- 2026-05-12: Playtest fixes now score Stage stars from both citadel HP and remaining in-siege Gold, start authored-route enemies on visible route cells instead of screen-edge anchors, reuse the same route cells for visible roads and movement, narrow prop build blocking to occupied footprint cells, and clean up result/ad retry copy.
- 2026-05-13: Playtest feedback pass adds citadel-proximity spawn-route filtering, obstacle footprint ownership, dice-cadence stage events, Wave-time barrier demolition, and archer/barracks range buffs for clearer fortress recovery.
- 2026-05-13: Follow-up playtest pass keeps tower build cards active after placement, allows Wave-time barrier demolition from the Flutter action bar, snaps promoted prop obstacles to single occupied cells, strengthens dice-cadence bosses, lowers starting/kill gold, and adds a once-per-stage Wave 3/4 artillery strike using a generated cannonball sprite.

## Risks

- Choosing a camera or map format too early could lock in poor content workflows.
- Over-scoping the first vertical slice could delay fun and profiling.
- Asset experimentation could outpace naming and export discipline.
- Reward, save, and ad boundaries could create duplication bugs if not modeled transactionally.
- Large-scale wave combat may produce too many overlapping SFX unless event categories are throttled and pooled.
- Sustain and ward-support enemies could create late-wave stall states if heal cadence, ward uptime, or elite overlap drift too high during future balance passes.
- The new tile-grid placement model may expose more buildable cells than the old slot template flow, so economy pacing and tower-count pressure should be watched during the next balance pass.
- The compact battle HUD and status banner now rely on tighter horizontal packing, so any future HUD additions should be checked on narrow Android portrait widths before shipping.
- A full all-direction pivot would multiply enemy art and route-authoring complexity, so it should favor authored multi-front corridors before any attempt at unrestricted roaming enemies.
- Web validation is now part of the product-spec contract, so future UI and gameplay work should expose enough observable state for Playwright-driven QA on top of Flame rendering.
- Citadel position variance can improve map identity, but if introduced too broadly before Act 1 is stable it may weaken onboarding and increase implementation churn.

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
- Enemy sprites can now include matching `walk_02` and `walk_03` frames generated from the same LPC source pipeline as the base frame, reducing runtime fallback and walk-animation asset mismatch risk.
- Enemy bases, `walk_02`, and `walk_03` now all come from the same LPC ZIP export mapping, reducing animation mismatch and bad-source drift across rerenders.
- The late campaign now exposes heal, ward, summon, and buff support roles through a broader 15-unit roster instead of reusing the same few enemy patterns.
- The sample campaign battlefield is now authored as tile data first, which fixes path-adjacent placement false negatives and makes path centering consistent across the full 30-stage arc.
- Battle UI guidance now lives in Flutter overlays above a dedicated gameplay viewport, reducing overlap between status text, tower controls, and the `Wave` CTA during live combat.
- Enemy visibility at wave start is now tied to immediate on-path placement rather than waiting for the first movement update, which makes early spawns easier to validate during gameplay smoke tests.
- Combat audio now uses a stricter queued SFX budget with burst suppression, and hero placement UX now exposes valid slots plus reliable reselection affordances so mobile playtests are less likely to stall on audio spam or hidden controls.
- The top battle HUD now reports remaining enemies for the active Cycle instead of only currently alive enemies, and recovery states now hold on a manual-ready state until the player starts the next Cycle.
- Citadel Siege v2 stages now reuse environment props as non-blocking edge set dressing, keeping the central build space readable while avoiding empty green battlefields.
- Siege enemies now commit to attacking the first player barrier on their assigned route instead of always seeking an alternate route, and repeated combat SFX are more aggressively coalesced for Android stability.
