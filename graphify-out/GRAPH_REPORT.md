# Graph Report - C:\Users\min21\Desktop\flutter_grame\depense_game  (2026-04-18)

## Corpus Check
- 73 files · ~1,226,093 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 746 nodes · 1163 edges · 38 communities detected
- Extraction: 96% EXTRACTED · 4% INFERRED · 0% AMBIGUOUS · INFERRED: 43 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_Community 0|Community 0]]
- [[_COMMUNITY_Community 1|Community 1]]
- [[_COMMUNITY_Community 2|Community 2]]
- [[_COMMUNITY_Community 3|Community 3]]
- [[_COMMUNITY_Community 4|Community 4]]
- [[_COMMUNITY_Community 5|Community 5]]
- [[_COMMUNITY_Community 6|Community 6]]
- [[_COMMUNITY_Community 7|Community 7]]
- [[_COMMUNITY_Community 8|Community 8]]
- [[_COMMUNITY_Community 9|Community 9]]
- [[_COMMUNITY_Community 10|Community 10]]
- [[_COMMUNITY_Community 11|Community 11]]
- [[_COMMUNITY_Community 12|Community 12]]
- [[_COMMUNITY_Community 13|Community 13]]
- [[_COMMUNITY_Community 14|Community 14]]
- [[_COMMUNITY_Community 15|Community 15]]
- [[_COMMUNITY_Community 16|Community 16]]
- [[_COMMUNITY_Community 17|Community 17]]
- [[_COMMUNITY_Community 18|Community 18]]
- [[_COMMUNITY_Community 19|Community 19]]
- [[_COMMUNITY_Community 20|Community 20]]
- [[_COMMUNITY_Community 21|Community 21]]
- [[_COMMUNITY_Community 22|Community 22]]
- [[_COMMUNITY_Community 23|Community 23]]
- [[_COMMUNITY_Community 24|Community 24]]
- [[_COMMUNITY_Community 25|Community 25]]
- [[_COMMUNITY_Community 26|Community 26]]
- [[_COMMUNITY_Community 27|Community 27]]
- [[_COMMUNITY_Community 28|Community 28]]
- [[_COMMUNITY_Community 29|Community 29]]
- [[_COMMUNITY_Community 30|Community 30]]
- [[_COMMUNITY_Community 31|Community 31]]
- [[_COMMUNITY_Community 32|Community 32]]
- [[_COMMUNITY_Community 33|Community 33]]
- [[_COMMUNITY_Community 34|Community 34]]
- [[_COMMUNITY_Community 35|Community 35]]
- [[_COMMUNITY_Community 36|Community 36]]
- [[_COMMUNITY_Community 37|Community 37]]

## God Nodes (most connected - your core abstractions)
1. `line()` - 44 edges
2. `new_canvas()` - 26 edges
3. `shadow()` - 26 edges
4. `main()` - 26 edges
5. `poly()` - 19 edges
6. `rect()` - 18 edges
7. `open_enemy()` - 16 edges
8. `save_enemy()` - 16 edges
9. `new_canvas()` - 13 edges
10. `shadow()` - 13 edges

## Surprising Connections (you probably didn't know these)
- `render_stage()` --calls--> `Text`  [INFERRED]
  C:\Users\min21\Desktop\flutter_grame\depense_game\tools\generate_map_scene_previews.py → C:\Users\min21\Desktop\flutter_grame\depense_game\lib\app\screens\title_screen.dart
- `draw_path()` --calls--> `line()`  [INFERRED]
  C:\Users\min21\Desktop\flutter_grame\depense_game\tools\generate_map_scene_previews.py → C:\Users\min21\Desktop\flutter_grame\depense_game\tools\generate_environment_props.py
- `draw_banner()` --calls--> `line()`  [INFERRED]
  C:\Users\min21\Desktop\flutter_grame\depense_game\tools\generate_tower_sprites.py → C:\Users\min21\Desktop\flutter_grame\depense_game\tools\generate_environment_props.py
- `draw_chain()` --calls--> `line()`  [INFERRED]
  C:\Users\min21\Desktop\flutter_grame\depense_game\tools\generate_tower_sprites.py → C:\Users\min21\Desktop\flutter_grame\depense_game\tools\generate_environment_props.py
- `archer_tower()` --calls--> `line()`  [INFERRED]
  C:\Users\min21\Desktop\flutter_grame\depense_game\tools\generate_tower_sprites.py → C:\Users\min21\Desktop\flutter_grame\depense_game\tools\generate_environment_props.py

## Communities

### Community 0 - "Community 0"
Cohesion: 0.02
Nodes (112): _adjustDamageForEnemy, advance, _applyBurn, _applyEnemyAbility, _applyTowerDamage, _applyWarlockWard, _backgroundShader, _ballistaPriorityForKind (+104 more)

### Community 1 - "Community 1"
Cohesion: 0.03
Nodes (67): build, DepenseApp, MaterialApp, _PortraitOnlyScaffold, Scaffold, build, _HelpCard, HelpScreen (+59 more)

### Community 2 - "Community 2"
Cohesion: 0.03
Nodes (60): AppBootstrap, GameSettingsRecord, PlayerProfile, RewardClaimRecord, StageProgressRecord, UpgradeNodeRecord, CampaignOverview, _checkStageUnlocked (+52 more)

### Community 3 - "Community 3"
Cohesion: 0.04
Nodes (47): deleteAllByClaimKeySync, deleteAllByIndex, deleteAllByIndexSync, deleteAllByNodeIdSync, deleteAllByStageNumberSync, deleteByClaimKeySync, deleteByIndex, deleteByIndexSync (+39 more)

### Community 4 - "Community 4"
Cohesion: 0.05
Nodes (40): _act2Enemy, Act2SiegeData, _fg, FrontSpawnGroupDefinition, EnemyDefinition, AssaultCycleDefinition, _evaluateObjective, evaluateRun (+32 more)

### Community 5 - "Community 5"
Cohesion: 0.05
Nodes (41): build, _BuildBar, _BuildBarState, _BuildCard, _BuildSummaryStrip, Center, Container, dispose (+33 more)

### Community 6 - "Community 6"
Cohesion: 0.06
Nodes (34): _baseHealthForStage, _biomeForStage, _BiomeProfile, _buildEarlyGameWave, _buildFinalBossWave, _buildLateGameWave, _buildMidGameWave, _buildUpperMidGameWave (+26 more)

### Community 7 - "Community 7"
Cohesion: 0.07
Nodes (28): add, build, _groundShapeForTheme, _isSuppressed, MapTextureMark, MapTexturePlan, MapTexturePlanner, _pathDetailColor (+20 more)

### Community 8 - "Community 8"
Cohesion: 0.09
Nodes (25): FlutterWindow(), OnCreate(), RegisterPlugins(), wWinMain(), CreateAndAttachConsole(), GetCommandLineArguments(), Utf8FromUtf16(), Create() (+17 more)

### Community 9 - "Community 9"
Cohesion: 0.3
Nodes (31): bone_pile(), brazier_large(), brazier_stand(), broken_barrel(), broken_coffin(), campfire(), candle_cluster(), chain_post() (+23 more)

### Community 10 - "Community 10"
Cohesion: 0.07
Nodes (25): actForSiege, computeFailureMetaGold, computeFailureXp, computeSiegeTokensEarned, cycleCompletionGoldBonus, cycleProgressRatio, SiegeRewardFormulas, AudioCatalog (+17 more)

### Community 11 - "Community 11"
Cohesion: 0.24
Nodes (19): main(), open_enemy(), polish_banner_captain(), polish_bastion_overlord(), polish_bastion_priest(), polish_bone_archer(), polish_corrupted_knight(), polish_cult_adept() (+11 more)

### Community 12 - "Community 12"
Cohesion: 0.46
Nodes (18): bandit_stockade(), bastion_wall_chunk(), cemetery_statue(), checkpoint_tower(), cursed_chapel_front(), gate_ruin(), infernal_gate(), line() (+10 more)

### Community 13 - "Community 13"
Cohesion: 0.33
Nodes (17): apply_branch_variant(), archer_tower(), ballista(), coin_mill(), draw_banner(), draw_chain(), draw_ellipse(), draw_polygon() (+9 more)

### Community 14 - "Community 14"
Cohesion: 0.37
Nodes (15): base_defender(), defender_body(), halberd(), helmet(), line(), main(), new_canvas(), poly() (+7 more)

### Community 15 - "Community 15"
Cohesion: 0.12
Nodes (15): build, _buildActionButton, _buildNextMissionCard, _buildSecondaryActions, _buildStageHistoryGrid, _buildStatIndicator, _buildTopBar, Column (+7 more)

### Community 16 - "Community 16"
Cohesion: 0.16
Nodes (11): byId, costForLevel, effectSummary, MetaUpgradeCatalog, MetaUpgradeDefinition, nextEffectSummary, resolve, ResolvedMetaUpgrades (+3 more)

### Community 17 - "Community 17"
Cohesion: 0.27
Nodes (13): Text, draw_anchor_cluster(), draw_crest_overlay(), draw_ground_texture(), draw_path(), draw_slots(), gradient_background(), is_texture_suppressed() (+5 more)

### Community 18 - "Community 18"
Cohesion: 0.22
Nodes (12): configure_character(), download_zip(), extract_frames(), main(), process_enemy(), LPC Character Generator - Batch 1 Enemy 4-Direction Sprite Extractor Uses Playwr, Configure LPC character using the site's JS API., Trigger ZIP download and return the zip file path. (+4 more)

### Community 19 - "Community 19"
Cohesion: 0.2
Nodes (9): CampaignOverview, MetaUpgradePurchaseResult, MetaUpgradeSnapshot, ObjectiveCompletionSnapshot, PlayerProgressSnapshot, RewardClaimResult, StageCompletionResult, StageProgressSnapshot (+1 more)

### Community 20 - "Community 20"
Cohesion: 0.43
Nodes (7): configure_character(), download_zip(), extract_frames(), main(), process_enemy(), LPC Character Generator - Batch 2 Enemy 4-Direction Sprite Extractor Enemies: ba, write_metadata()

### Community 21 - "Community 21"
Cohesion: 0.43
Nodes (6): list_runs(), main(), parse_args(), Return capture run directories sorted oldest-first by name., Print a one-line summary of a capture run directory., report_run()

### Community 22 - "Community 22"
Cohesion: 0.67
Nodes (3): main(), Remove black backgrounds from environment sprites. Pixels where R, G, B are all, remove_black_bg()

### Community 23 - "Community 23"
Cohesion: 0.67
Nodes (3): check_enemy(), main(), Return a list of issue strings for the given enemy folder.

### Community 24 - "Community 24"
Cohesion: 1.0
Nodes (1): MainActivity

### Community 25 - "Community 25"
Cohesion: 1.0
Nodes (1): AudioSettingsSnapshot

### Community 26 - "Community 26"
Cohesion: 1.0
Nodes (1): RunAssistChoice

### Community 27 - "Community 27"
Cohesion: 1.0
Nodes (0): 

### Community 28 - "Community 28"
Cohesion: 1.0
Nodes (0): 

### Community 29 - "Community 29"
Cohesion: 1.0
Nodes (0): 

### Community 30 - "Community 30"
Cohesion: 1.0
Nodes (0): 

### Community 31 - "Community 31"
Cohesion: 1.0
Nodes (0): 

### Community 32 - "Community 32"
Cohesion: 1.0
Nodes (0): 

### Community 33 - "Community 33"
Cohesion: 1.0
Nodes (0): 

### Community 34 - "Community 34"
Cohesion: 1.0
Nodes (0): 

### Community 35 - "Community 35"
Cohesion: 1.0
Nodes (0): 

### Community 36 - "Community 36"
Cohesion: 1.0
Nodes (0): 

### Community 37 - "Community 37"
Cohesion: 1.0
Nodes (0): 

## Knowledge Gaps
- **460 isolated node(s):** `Remove black backgrounds from environment sprites. Pixels where R, G, B are all`, `Normalize the four outlier environment sprites that were imported at 1024x1024.`, `MainActivity`, `package:depense_game/app/depense_app.dart`, `DepenseApp` (+455 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **Thin community `Community 24`** (2 nodes): `MainActivity.kt`, `MainActivity`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 25`** (2 nodes): `store_models.dart`, `AudioSettingsSnapshot`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 26`** (2 nodes): `run_assist.dart`, `RunAssistChoice`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 27`** (1 nodes): `build.gradle.kts`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 28`** (1 nodes): `settings.gradle.kts`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 29`** (1 nodes): `build.gradle.kts`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 30`** (1 nodes): `app_flow_state.dart`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 31`** (1 nodes): `sample_campaign.dart`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 32`** (1 nodes): `audio_event.dart`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 33`** (1 nodes): `generate_lpc_enemy_sprites.ps1`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 34`** (1 nodes): `generated_plugin_registrant.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 35`** (1 nodes): `resource.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 36`** (1 nodes): `utils.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 37`** (1 nodes): `win32_window.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Text` connect `Community 17` to `Community 1`?**
  _High betweenness centrality (0.154) - this node is a cross-community bridge._
- **Why does `line()` connect `Community 9` to `Community 17`, `Community 11`, `Community 13`?**
  _High betweenness centrality (0.143) - this node is a cross-community bridge._
- **Are the 25 inferred relationships involving `line()` (e.g. with `draw_path()` and `draw_banner()`) actually correct?**
  _`line()` has 25 INFERRED edges - model-reasoned connections that need verification._
- **What connects `Remove black backgrounds from environment sprites. Pixels where R, G, B are all`, `Normalize the four outlier environment sprites that were imported at 1024x1024.`, `MainActivity` to the rest of the system?**
  _460 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Community 0` be split into smaller, more focused modules?**
  _Cohesion score 0.02 - nodes in this community are weakly interconnected._
- **Should `Community 1` be split into smaller, more focused modules?**
  _Cohesion score 0.03 - nodes in this community are weakly interconnected._
- **Should `Community 2` be split into smaller, more focused modules?**
  _Cohesion score 0.03 - nodes in this community are weakly interconnected._