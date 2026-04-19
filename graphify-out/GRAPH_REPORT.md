# Graph Report - .  (2026-04-19)

## Corpus Check
- 73 files ¡¤ ~1,226,093 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 745 nodes ¡¤ 1160 edges ¡¤ 37 communities detected
- Extraction: 96% EXTRACTED ¡¤ 4% INFERRED ¡¤ 0% AMBIGUOUS ¡¤ INFERRED: 43 edges (avg confidence: 0.8)
- Token cost: 0 input ¡¤ 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_Game Engine Core|Game Engine Core]]
- [[_COMMUNITY_App Bootstrap & UI|App Bootstrap & UI]]
- [[_COMMUNITY_App Shell & Screens|App Shell & Screens]]
- [[_COMMUNITY_Campaign & Meta Data|Campaign & Meta Data]]
- [[_COMMUNITY_Persistence Layer (Isar)|Persistence Layer (Isar)]]
- [[_COMMUNITY_Game Screen|Game Screen]]
- [[_COMMUNITY_Map Rendering & Tools|Map Rendering & Tools]]
- [[_COMMUNITY_Campaign Wave Data|Campaign Wave Data]]
- [[_COMMUNITY_Windows Runner|Windows Runner]]
- [[_COMMUNITY_Environment Props Gen|Environment Props Gen]]
- [[_COMMUNITY_Enemy Sprite Polish|Enemy Sprite Polish]]
- [[_COMMUNITY_Reward Formulas|Reward Formulas]]
- [[_COMMUNITY_Environment Landmarks Gen|Environment Landmarks Gen]]
- [[_COMMUNITY_Tower Sprites Gen|Tower Sprites Gen]]
- [[_COMMUNITY_Audio System|Audio System]]
- [[_COMMUNITY_Barracks Defender Gen|Barracks Defender Gen]]
- [[_COMMUNITY_Map Scene Previews Gen|Map Scene Previews Gen]]
- [[_COMMUNITY_LPC Sprite Batch 1|LPC Sprite Batch 1]]
- [[_COMMUNITY_Progression Models|Progression Models]]
- [[_COMMUNITY_LPC Sprite Batch 2|LPC Sprite Batch 2]]
- [[_COMMUNITY_QA Capture Cleanup|QA Capture Cleanup]]
- [[_COMMUNITY_Sprite BG Remover|Sprite BG Remover]]
- [[_COMMUNITY_Enemy Asset Validator|Enemy Asset Validator]]
- [[_COMMUNITY_Android Entry Point|Android Entry Point]]
- [[_COMMUNITY_Audio Settings Store|Audio Settings Store]]
- [[_COMMUNITY_Run Assist|Run Assist]]
- [[_COMMUNITY_Android Build (root)|Android Build (root)]]
- [[_COMMUNITY_Android Settings|Android Settings]]
- [[_COMMUNITY_Android App Build|Android App Build]]
- [[_COMMUNITY_App Flow State|App Flow State]]
- [[_COMMUNITY_Sample Campaign|Sample Campaign]]
- [[_COMMUNITY_Audio Events|Audio Events]]
- [[_COMMUNITY_LPC Sprite Script|LPC Sprite Script]]
- [[_COMMUNITY_Windows Plugin Header|Windows Plugin Header]]
- [[_COMMUNITY_Windows Resource Header|Windows Resource Header]]
- [[_COMMUNITY_Windows Utils Header|Windows Utils Header]]
- [[_COMMUNITY_Windows Win32 Header|Windows Win32 Header]]

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
  C:\Users\min21\Desktop\flutter_grame\depense_game\tools\generate_map_scene_previews.py ¡æ lib\app\screens\title_screen.dart
- `draw_path()` --calls--> `line()`  [INFERRED]
  C:\Users\min21\Desktop\flutter_grame\depense_game\tools\generate_map_scene_previews.py ¡æ C:\Users\min21\Desktop\flutter_grame\depense_game\tools\generate_environment_props.py
- `draw_banner()` --calls--> `line()`  [INFERRED]
  C:\Users\min21\Desktop\flutter_grame\depense_game\tools\generate_tower_sprites.py ¡æ C:\Users\min21\Desktop\flutter_grame\depense_game\tools\generate_environment_props.py
- `draw_chain()` --calls--> `line()`  [INFERRED]
  C:\Users\min21\Desktop\flutter_grame\depense_game\tools\generate_tower_sprites.py ¡æ C:\Users\min21\Desktop\flutter_grame\depense_game\tools\generate_environment_props.py
- `archer_tower()` --calls--> `line()`  [INFERRED]
  C:\Users\min21\Desktop\flutter_grame\depense_game\tools\generate_tower_sprites.py ¡æ C:\Users\min21\Desktop\flutter_grame\depense_game\tools\generate_environment_props.py

## Communities

### Community 0 - "Game Engine Core"
Cohesion: 0.02
Nodes (112): _adjustDamageForEnemy, advance, _applyBurn, _applyEnemyAbility, _applyTowerDamage, _applyWarlockWard, _backgroundShader, _ballistaPriorityForKind (+104 more)

### Community 1 - "App Bootstrap & UI"
Cohesion: 0.03
Nodes (66): AppBootstrap, build, Card, Container, initState, _load, MetaUpgradesScreen, _MetaUpgradesScreenState (+58 more)

### Community 2 - "App Shell & Screens"
Cohesion: 0.03
Nodes (68): build, DepenseApp, MaterialApp, _PortraitOnlyScaffold, Scaffold, build, _HelpCard, HelpScreen (+60 more)

### Community 3 - "Campaign & Meta Data"
Cohesion: 0.04
Nodes (50): _act2Enemy, Act2SiegeData, _fg, FrontSpawnGroupDefinition, byId, costForLevel, effectSummary, MetaUpgradeCatalog (+42 more)

### Community 4 - "Persistence Layer (Isar)"
Cohesion: 0.04
Nodes (47): deleteAllByClaimKeySync, deleteAllByIndex, deleteAllByIndexSync, deleteAllByNodeIdSync, deleteAllByStageNumberSync, deleteByClaimKeySync, deleteByIndex, deleteByIndexSync (+39 more)

### Community 5 - "Game Screen"
Cohesion: 0.05
Nodes (42): build, _buildActionButton, _BuildBar, _BuildBarState, _BuildCard, _BuildSummaryStrip, Center, Container (+34 more)

### Community 6 - "Map Rendering & Tools"
Cohesion: 0.07
Nodes (28): add, build, _groundShapeForTheme, _isSuppressed, MapTextureMark, MapTexturePlan, MapTexturePlanner, _pathDetailColor (+20 more)

### Community 7 - "Campaign Wave Data"
Cohesion: 0.06
Nodes (34): _baseHealthForStage, _biomeForStage, _BiomeProfile, _buildEarlyGameWave, _buildFinalBossWave, _buildLateGameWave, _buildMidGameWave, _buildUpperMidGameWave (+26 more)

### Community 8 - "Windows Runner"
Cohesion: 0.09
Nodes (25): FlutterWindow(), OnCreate(), RegisterPlugins(), wWinMain(), CreateAndAttachConsole(), GetCommandLineArguments(), Utf8FromUtf16(), Create() (+17 more)

### Community 9 - "Environment Props Gen"
Cohesion: 0.3
Nodes (31): bone_pile(), brazier_large(), brazier_stand(), broken_barrel(), broken_coffin(), campfire(), candle_cluster(), chain_post() (+23 more)

### Community 10 - "Enemy Sprite Polish"
Cohesion: 0.24
Nodes (19): main(), open_enemy(), polish_banner_captain(), polish_bastion_overlord(), polish_bastion_priest(), polish_bone_archer(), polish_corrupted_knight(), polish_cult_adept() (+11 more)

### Community 11 - "Reward Formulas"
Cohesion: 0.1
Nodes (17): actForSiege, computeFailureMetaGold, computeFailureXp, computeSiegeTokensEarned, cycleCompletionGoldBonus, cycleProgressRatio, SiegeRewardFormulas, dart:math (+9 more)

### Community 12 - "Environment Landmarks Gen"
Cohesion: 0.46
Nodes (18): bandit_stockade(), bastion_wall_chunk(), cemetery_statue(), checkpoint_tower(), cursed_chapel_front(), gate_ruin(), infernal_gate(), line() (+10 more)

### Community 13 - "Tower Sprites Gen"
Cohesion: 0.33
Nodes (17): apply_branch_variant(), archer_tower(), ballista(), coin_mill(), draw_banner(), draw_chain(), draw_ellipse(), draw_polygon() (+9 more)

### Community 14 - "Audio System"
Cohesion: 0.12
Nodes (15): AudioSettingsController, setMasterVolume, setMusicVolume, setMuted, setSfxVolume, GameSessionController, hydrate, SelectedTowerDetails (+7 more)

### Community 15 - "Barracks Defender Gen"
Cohesion: 0.37
Nodes (15): base_defender(), defender_body(), halberd(), helmet(), line(), main(), new_canvas(), poly() (+7 more)

### Community 16 - "Map Scene Previews Gen"
Cohesion: 0.27
Nodes (13): draw_anchor_cluster(), draw_crest_overlay(), draw_ground_texture(), draw_path(), draw_slots(), gradient_background(), is_texture_suppressed(), main() (+5 more)

### Community 17 - "LPC Sprite Batch 1"
Cohesion: 0.22
Nodes (12): configure_character(), download_zip(), extract_frames(), main(), process_enemy(), LPC Character Generator - Batch 1 Enemy 4-Direction Sprite Extractor Uses Playwr, Configure LPC character using the site's JS API., Trigger ZIP download and return the zip file path. (+4 more)

### Community 18 - "Progression Models"
Cohesion: 0.2
Nodes (9): CampaignOverview, MetaUpgradePurchaseResult, MetaUpgradeSnapshot, ObjectiveCompletionSnapshot, PlayerProgressSnapshot, RewardClaimResult, StageCompletionResult, StageProgressSnapshot (+1 more)

### Community 19 - "LPC Sprite Batch 2"
Cohesion: 0.43
Nodes (7): configure_character(), download_zip(), extract_frames(), main(), process_enemy(), LPC Character Generator - Batch 2 Enemy 4-Direction Sprite Extractor Enemies: ba, write_metadata()

### Community 20 - "QA Capture Cleanup"
Cohesion: 0.43
Nodes (6): list_runs(), main(), parse_args(), Return capture run directories sorted oldest-first by name., Print a one-line summary of a capture run directory., report_run()

### Community 21 - "Sprite BG Remover"
Cohesion: 0.67
Nodes (3): main(), Remove black backgrounds from environment sprites. Pixels where R, G, B are all, remove_black_bg()

### Community 22 - "Enemy Asset Validator"
Cohesion: 0.67
Nodes (3): check_enemy(), main(), Return a list of issue strings for the given enemy folder.

### Community 23 - "Android Entry Point"
Cohesion: 1.0
Nodes (1): MainActivity

### Community 24 - "Audio Settings Store"
Cohesion: 1.0
Nodes (1): AudioSettingsSnapshot

### Community 25 - "Run Assist"
Cohesion: 1.0
Nodes (1): RunAssistChoice

### Community 26 - "Android Build (root)"
Cohesion: 1.0
Nodes (0): 

### Community 27 - "Android Settings"
Cohesion: 1.0
Nodes (0): 

### Community 28 - "Android App Build"
Cohesion: 1.0
Nodes (0): 

### Community 29 - "App Flow State"
Cohesion: 1.0
Nodes (0): 

### Community 30 - "Sample Campaign"
Cohesion: 1.0
Nodes (0): 

### Community 31 - "Audio Events"
Cohesion: 1.0
Nodes (0): 

### Community 32 - "LPC Sprite Script"
Cohesion: 1.0
Nodes (0): 

### Community 33 - "Windows Plugin Header"
Cohesion: 1.0
Nodes (0): 

### Community 34 - "Windows Resource Header"
Cohesion: 1.0
Nodes (0): 

### Community 35 - "Windows Utils Header"
Cohesion: 1.0
Nodes (0): 

### Community 36 - "Windows Win32 Header"
Cohesion: 1.0
Nodes (0): 

## Knowledge Gaps
- **459 isolated node(s):** `Remove black backgrounds from environment sprites. Pixels where R, G, B are all`, `Normalize the four outlier environment sprites that were imported at 1024x1024.`, `MainActivity`, `package:depense_game/app/depense_app.dart`, `DepenseApp` (+454 more)
  These have ¡Â1 connection - possible missing edges or undocumented components.
- **Thin community `Android Entry Point`** (2 nodes): `MainActivity.kt`, `MainActivity`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Audio Settings Store`** (2 nodes): `store_models.dart`, `AudioSettingsSnapshot`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Run Assist`** (2 nodes): `run_assist.dart`, `RunAssistChoice`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Android Build (root)`** (1 nodes): `build.gradle.kts`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Android Settings`** (1 nodes): `settings.gradle.kts`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Android App Build`** (1 nodes): `build.gradle.kts`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `App Flow State`** (1 nodes): `app_flow_state.dart`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Sample Campaign`** (1 nodes): `sample_campaign.dart`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Audio Events`** (1 nodes): `audio_event.dart`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `LPC Sprite Script`** (1 nodes): `generate_lpc_enemy_sprites.ps1`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Windows Plugin Header`** (1 nodes): `generated_plugin_registrant.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Windows Resource Header`** (1 nodes): `resource.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Windows Utils Header`** (1 nodes): `utils.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Windows Win32 Header`** (1 nodes): `win32_window.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Text` connect `Map Scene Previews Gen` to `App Shell & Screens`?**
  _High betweenness centrality (0.154) - this node is a cross-community bridge._
- **Why does `line()` connect `Environment Props Gen` to `Map Scene Previews Gen`, `Enemy Sprite Polish`, `Tower Sprites Gen`?**
  _High betweenness centrality (0.143) - this node is a cross-community bridge._
- **Are the 25 inferred relationships involving `line()` (e.g. with `draw_path()` and `draw_banner()`) actually correct?**
  _`line()` has 25 INFERRED edges - model-reasoned connections that need verification._
- **What connects `Remove black backgrounds from environment sprites. Pixels where R, G, B are all`, `Normalize the four outlier environment sprites that were imported at 1024x1024.`, `MainActivity` to the rest of the system?**
  _459 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Game Engine Core` be split into smaller, more focused modules?**
  _Cohesion score 0.02 - nodes in this community are weakly interconnected._
- **Should `App Bootstrap & UI` be split into smaller, more focused modules?**
  _Cohesion score 0.03 - nodes in this community are weakly interconnected._
- **Should `App Shell & Screens` be split into smaller, more focused modules?**
  _Cohesion score 0.03 - nodes in this community are weakly interconnected._