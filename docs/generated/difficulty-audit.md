# Difficulty Audit

Generated from current Dart definitions. Rerun `flutter test tool/export_difficulty_audit.dart` after balance changes.

## Scale

- Wave pressure uses the same formula as `current-game-data-snapshot.md`: HP 60%, wall damage 25%, tower contact damage 15%.
- Stage score is the rounded average of its wave pressure values.
- Peak is the highest wave pressure in the Stage, usually the final wave.
- Ramp is the percentage increase from Wave 1 to the peak wave.
- Event boss HP ratio compares boss HP to that Stage peak pressure. It is a rough tuning signal, not a combat simulation.

## Stage And Wave Difficulty

| Stage | Gold | W1 | W2 | W3 | W4 | Stage Score | Peak | Ramp | Flags |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| 1 | 230 | 90 | 162 | 234 | - | 162 | 234 | 160% | - |
| 2 | 245 | 105 | 161 | 217 | 273 | 189 | 273 | 160% | bombardment |
| 3 | 260 | 120 | 182 | 246 | 309 | 214 | 309 | 158% | bombardment |
| 4 | 275 | 133 | 205 | 275 | 346 | 240 | 346 | 160% | event boss, bombardment |
| 5 | 290 | 146 | 225 | 305 | 383 | 265 | 383 | 162% | bombardment |
| 6 | 315 | 162 | 247 | 334 | 417 | 290 | 417 | 157% | bombardment |
| 7 | 330 | 175 | 267 | 362 | 454 | 315 | 454 | 159% | event boss, bombardment |
| 8 | 345 | 189 | 290 | 390 | 493 | 341 | 493 | 161% | bombardment |
| 9 | 360 | 202 | 312 | 419 | 527 | 365 | 527 | 161% | bombardment |
| 10 | 375 | 218 | 333 | 449 | 564 | 391 | 564 | 159% | event boss, bombardment |
| 11 | 400 | 231 | 342 | 454 | 564 | 398 | 564 | 144% | bombardment |
| 12 | 415 | 245 | 363 | 483 | 602 | 423 | 602 | 146% | bombardment |
| 13 | 435 | 260 | 385 | 510 | 634 | 447 | 634 | 144% | event boss, bombardment |
| 14 | 455 | 272 | 405 | 538 | 669 | 471 | 669 | 146% | bombardment |
| 15 | 470 | 287 | 426 | 565 | 703 | 495 | 703 | 145% | bombardment |
| 16 | 495 | 301 | 448 | 593 | 739 | 520 | 739 | 146% | event boss, bombardment |
| 17 | 520 | 315 | 466 | 622 | 771 | 544 | 771 | 145% | bombardment |
| 18 | 540 | 329 | 489 | 645 | 806 | 567 | 806 | 145% | bombardment |
| 19 | 560 | 343 | 508 | 673 | 840 | 591 | 840 | 145% | event boss, bombardment |
| 20 | 585 | 357 | 530 | 703 | 874 | 616 | 874 | 145% | bombardment |
| 21 | 610 | 377 | 546 | 713 | 883 | 630 | 883 | 134% | bombardment, 4 fronts |
| 22 | 635 | 396 | 572 | 751 | 928 | 662 | 928 | 134% | event boss, bombardment, 4 fronts |
| 23 | 660 | 413 | 600 | 786 | 972 | 693 | 972 | 135% | bombardment, 4 fronts |
| 24 | 685 | 434 | 628 | 823 | 1018 | 726 | 1018 | 135% | bombardment, 4 fronts |
| 25 | 710 | 452 | 655 | 859 | 1062 | 757 | 1062 | 135% | event boss, bombardment, 4 fronts |
| 26 | 740 | 471 | 683 | 895 | 1108 | 789 | 1108 | 135% | bombardment, 4 fronts |
| 27 | 770 | 491 | 710 | 931 | 1152 | 821 | 1152 | 135% | bombardment, 4 fronts |
| 28 | 795 | 510 | 737 | 966 | 1195 | 852 | 1195 | 134% | event boss, bombardment, 4 fronts |
| 29 | 825 | 528 | 767 | 1005 | 1241 | 885 | 1241 | 135% | bombardment, 4 fronts |
| 30 | 850 | 548 | 793 | 1039 | 1285 | 916 | 1285 | 134% | bombardment, 4 fronts, normal boss |

## Event Boss Stats

| Stage | Event ID | Boss | Enemy | HP | HP/Peak | Physical Taken | Wall | Shockwave | Tower Contact | HP Mult | Damage Mult | Scale |
| ---: | --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 4 | `elite_shield_breaker` | 정예 방패병 | `shieldInfantry` | 1000 | 2.9x | 100% | 72 | 30.2 | 74 | 10.05 | 4.65 | 1.65 |
| 7 | `boss_banner_captain` | 깃발 대장 | `bannerCaptain` | 1285 | 2.8x | 100% | 68 | 28.6 | 55 | 10.65 | 4.95 | 1.7 |
| 7 | `elite_grave_guard` | 정예 묘지 경비병 | `graveGuard` | 1285 | 2.8x | 100% | 74 | 31.1 | 76 | 9.6 | 4.8 | 1.68 |
| 10 | `boss_banner_captain` | 깃발 대장 | `bannerCaptain` | 1570 | 2.8x | 100% | 68 | 28.6 | 55 | 10.65 | 4.95 | 1.7 |
| 10 | `elite_grave_guard` | 정예 묘지 경비병 | `graveGuard` | 1570 | 2.8x | 100% | 76 | 31.9 | 78 | 9.6 | 4.8 | 1.68 |
| 13 | `boss_corrupted_knight` | 타락 기사 | `corruptedKnight` | 1940 | 3.1x | 100% | 75 | 31.5 | 80 | 9.45 | 4.95 | 1.72 |
| 13 | `boss_warlock` | 암흑 주술사 | `warlock` | 1940 | 3.1x | 100% | 65 | 27.3 | 56 | 9.75 | 4.74 | 1.7 |
| 16 | `boss_corrupted_knight` | 타락 기사 | `corruptedKnight` | 2310 | 3.1x | 100% | 75 | 31.5 | 82 | 9.45 | 4.95 | 1.72 |
| 16 | `boss_warlock` | 암흑 주술사 | `warlock` | 2310 | 3.1x | 100% | 65 | 27.3 | 56 | 9.75 | 4.74 | 1.7 |
| 19 | `boss_corrupted_knight` | 타락 기사 | `corruptedKnight` | 2680 | 3.2x | 100% | 75 | 31.5 | 84 | 9.45 | 4.95 | 1.72 |
| 19 | `boss_warlock` | 암흑 주술사 | `warlock` | 2680 | 3.2x | 100% | 65 | 27.3 | 56 | 9.75 | 4.74 | 1.7 |
| 22 | `boss_bastion_priest` | 성채 사제 | `bastionPriest` | 3130 | 3.4x | 100% | 66 | 27.7 | 60 | 9.3 | 4.8 | 1.74 |
| 22 | `boss_bastion_overlord` | 성채 군주 | `bastionOverlord` | 3130 | 3.4x | 100% | 78 | 32.8 | 86 | 5.25 | 4.14 | 1.86 |
| 25 | `boss_bastion_priest` | 성채 사제 | `bastionPriest` | 3580 | 3.4x | 100% | 66 | 27.7 | 60 | 9.3 | 4.8 | 1.74 |
| 25 | `boss_bastion_overlord` | 성채 군주 | `bastionOverlord` | 3580 | 3.4x | 100% | 78 | 32.8 | 88 | 5.25 | 4.14 | 1.86 |
| 28 | `boss_bastion_priest` | 성채 사제 | `bastionPriest` | 4030 | 3.4x | 100% | 66 | 27.7 | 60 | 9.3 | 4.8 | 1.74 |
| 28 | `boss_bastion_overlord` | 성채 군주 | `bastionOverlord` | 4030 | 3.4x | 100% | 78 | 32.8 | 88 | 5.25 | 4.14 | 1.86 |

## Normal Boss Appearances

| Stage | Wave | Boss | Count | HP Each | Physical Taken | Wall | Shockwave | Tower Contact |
| ---: | ---: | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| 30 | 4 | `bastionOverlord` | 1 | 2480 | 55% | 15 | 6.3 | 27 |

## Tuning Notes

- Stage 1-10 now target about 160% intra-stage ramp, Stage 11-20 target about 145%, and Stage 21-30 target about 135%.
- Event boss HP now starts at 1000 on Stage 4, rises by 285 per event tier through Stage 10, by 370 per tier through Stage 19, and by 450 per tier through Stage 28.
- Stage 7 and Stage 10 `elite_grave_guard` no longer spike above other event bosses; their HP now matches the same Stage-based event boss curve.
- Event boss damage keeps low-damage casters/supports mostly intact and caps high-damage wall breakers so early bosses cannot out-damage late bosses.
- Stage 30 has the only normal `bastionOverlord` in assault cycle data, with physical resistance still active at 55%.
