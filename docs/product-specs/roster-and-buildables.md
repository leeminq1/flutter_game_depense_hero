# Roster And Buildables

## Purpose

This document maps the current roster into the new multi-front siege format so implementation can proceed without inventing a new enemy set.

## Defense Roster

The existing seven buildables remain the starting roster:

- Archer Tower
- Guard Barracks
- Mage Obelisk
- Frost Shrine
- Coin Mill
- Ballista
- Emberkeep

## Hero Roster V1

Heroes are stage-local gold purchases, not permanent progression in v1.

The player buys a hero during the current Stage, places it on a valid empty tile, and may manually move it by selecting the hero and tapping another valid empty tile. Heroes do not auto-roam.

| Hero | Unlock Stage | Primary Job |
| --- | --- | --- |
| Knight | Stage 1 | durable close-range holder near the citadel |
| Archer | Stage 5 | long-range support and leak cleanup |
| Mage | Stage 10 | magic burst against armor and clusters |
| Ninja | Stage 15 | fast single-target cleanup |
| Paladin | Stage 20 | expensive frontline anchor and elite duelist |

Stage 25 opens the direction for advanced hero upgrades after the basic five-hero set is proven.

## Buildable Jobs In Citadel Siege

| Tower | Primary Job | Best Use In Multi-Front Play |
| --- | --- | --- |
| Archer Tower | cheap general DPS | west and east outer-ring coverage, support pickoff |
| Guard Barracks | stall and contact control | fallback pockets, inner-ring emergency lane hold |
| Mage Obelisk | anti-armor and chain burst | inner-ring cross-coverage, east and south elite response |
| Frost Shrine | group control | front stabilization, revive and speed-wave suppression |
| Coin Mill | economy engine | supply node investment, safest outer-ring node first |
| Ballista | anti-elite and backline pickoff | inner-ring boss lane and support-sniping anchor |
| Emberkeep | area denial and attrition | undead cleanup, dense four-front overlap zones |

## Front Identity

Each front should feel like it has its own tactical personality.

| Front | Identity | Typical Threat |
| --- | --- | --- |
| West | fast flank pressure | Raiders, Scouts, Wolf Scouts |
| East | armored front pressure | Shield Infantry, leaders, cult escorts |
| North | undead attrition | Skeletons, Bone Archers, Grave Guards |
| South | support-heavy siege pressure | Plague Bearers, Warlocks, Bastion support |

## Front Color Language

Use these telegraph colors consistently:

| Front | Color |
| --- | --- |
| North | `#4488FF` |
| South | `#FF4444` |
| East | `#44FF88` |
| West | `#FFCC44` |

## Enemy Usage By Front

### West Front

- Role: fast greed punishment and leak pressure
- Primary enemies: Raider, Scout, Wolf Scout, Banner Captain
- Best answers: Archer Tower, Frost Shrine, Guard Barracks

### East Front

- Role: armor and leadership pressure
- Primary enemies: Shield Infantry, Banner Captain, Cult Adept
- Best answers: Mage Obelisk, Ballista, focused support pickoff

### North Front

- Role: revive and attrition tax
- Primary enemies: Skeleton, Bone Archer, Grave Guard, Corrupted Knight later
- Best answers: Frost Shrine, Emberkeep, Barracks stall plus sustained damage

### South Front

- Role: support stacking and late siege pressure
- Primary enemies: Plague Bearer, Hex Sniper, Warlock, Bastion Priest, Bastion Overlord
- Best answers: Ballista pickoff, Mage Obelisk chain pressure, Emberkeep in clustered lanes

## Counter Mapping

| Enemy | Citadel Damage | Best Answers | Common Failure |
| --- | --- | --- | --- |
| Raider | 1 | Archer, Barracks | greed-open Coin Mill |
| Scout | 1 | Frost, Archer overlap | single slow tower line |
| Banner Captain | 2 | Archer focus, Ballista | letting aura sit behind the front |
| Wolf Scout | 1 | Frost, layered cheap DPS | one-lane-only solution |
| Shield Infantry | 2 | Mage, Ballista | archer-only defense |
| Cult Adept | 2 | Archer focus, Ballista | ignoring support priority |
| Skeleton | 1 | sustained DPS, Frost | one-shot-only logic |
| Bone Archer | 1 | Emberkeep, Frost | assuming one kill equals one body |
| Grave Guard | 3 | Mage, Ballista | pure control without damage |
| Plague Bearer | 2 | Ballista, focused burst | attrition races |
| Corrupted Knight | 4 | Ballista, Barracks stall | weak anti-elite windows |
| Hex Sniper | 2 | Ballista, fast focus | leaving ward support alive |
| Warlock | 3 | Ballista, support denial | letting summon loops repeat |
| Bastion Priest | 3 | burst focus, Ballista | splitting damage too wide |
| Bastion Overlord | 10 | full mixed roster | one-note build plans |

Rule:

- when an enemy reaches the citadel, it deals its fixed `Citadel Damage` value directly
- MVP does not multiply citadel damage by siege scaling formulas

## Cross-Front Mixing Rule

Acts 1-4 should teach mostly readable front identity.

Acts 5-6 may deliberately mix enemies across fronts to prevent formulaic answers.

Examples:

- South front gains more knights and priests
- East front receives support overlap
- West front may gain disruptive ranged units

## Boss Rule

The final boss must validate the whole roster, not just one answer.

The player should need:

- backline pickoff
- elite damage
- crowd control
- recovery discipline
- a stable economy base from earlier cycles
