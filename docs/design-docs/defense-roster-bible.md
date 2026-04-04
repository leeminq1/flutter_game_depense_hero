# Defense Roster Bible

## Purpose

Lock the role, placement fantasy, upgrade identity, and visual language of the player's towers and summoned defenders.

This document exists so tower sprites, upgrade art, balance work, and future content expansion stay aligned.

## Defense Layer Model

The defense side is built from three layers:

- `damage anchors`: archer, mage, ballista, emberkeep
- `control anchors`: barracks, frost shrine
- `economy anchors`: coin mill

The roster should reward mixed builds rather than one-tower spam.

## General Tower Rules

Every tower should communicate:

1. what role it serves
2. whether it is cheap, premium, or support
3. what kind of upgrade fantasy it will grow into

Visual implications:

- offensive towers need a visible weapon or magical focal point
- control towers need shrine, guard-post, or support geometry
- economy towers need peaceful but readable production signs
- upgrade tiers should change top silhouette, trim, and footprint richness, not only recolor

## Core Buildables

### Archer Tower

- Role: cheap general-purpose lane DPS
- Cost profile: low entry, easy early placement
- Stage fantasy: first reliable damage anchor
- Best targets: Raider, Scout, Cult Adept
- Weak matchups: heavy armor and very dense elite pushes
- Unique ability: every third shot becomes a heavier piercing volley
- Branch fantasy:
  - `Ranger`: disciplined long-range sentry
  - `Multishot`: bursty skirmish platform
- Placement guidance: corners, long straights, lanes with repeated line coverage
- Visual read: wooden watch post, green roof or banner, bow emblem or archer nest
- Upgrade tier art direction:
  - T1: simple field tower with one banner
  - T2: reinforced upper deck and clearer bow housing
  - T3: taller platform, stronger trim, elite marksman silhouette
- Current branch sprite direction:
  - `Ranger`: taller watchpost with twin banners and a stronger vertical sentry read
  - `Multishot`: wider firing deck with side bow arms and denser volley gear

### Guard Barracks

- Role: lane stall and body-block control
- Cost profile: moderate
- Stage fantasy: buys time and protects greedy builds
- Best targets: Scouts, Raiders, Corrupted Knight stall setups
- Weak matchups: heavy ranged support and prolonged attrition without backup
- Unique ability: defenders stagger enemies and cleave nearby threats
- Branch fantasy:
  - `Vanguard`: harder front-line brawl pressure
  - `Sentinel`: wider defensive control reach
- Placement guidance: path bends, late-lane emergency pads, spots that protect premium towers
- Visual read: squat military hut, shield crest, red banner, visible doorway
- Upgrade tier art direction:
  - T1: modest field barracks
  - T2: reinforced roof and shield plating
  - T3: command-post feel with larger crest and sturdier stone base
- Current branch sprite direction:
  - `Vanguard`: heavier shield-front gatehouse and thicker plated facade
  - `Sentinel`: longer outpost feel with wider guard platform and polearm cues

### Mage Obelisk

- Role: anti-armor burst and magical chain damage
- Cost profile: premium early-mid tower
- Stage fantasy: the answer to armored and clumped elites
- Best targets: Shield Infantry, Grave Guard support clusters, Corrupted Knight
- Weak matchups: very cheap early rushes if overbought
- Unique ability: chained arcane bursts jump across clustered enemies
- Branch fantasy:
  - `Storm`: faster, more chaining caster
  - `Rune`: slower but harder armor-breaking burst
- Placement guidance: central pads with broad influence over multiple lane segments
- Visual read: stone plinth plus crystal apex, purple glow, ritual geometry
- Upgrade tier art direction:
  - T1: compact obelisk
  - T2: wider rune base and brighter side channels
  - T3: taller crystal crown and stronger magical frame
- Current branch sprite direction:
  - `Storm`: split crystal crown and branching side rods
  - `Rune`: thicker monolith with heavier rune-slab framing

### Frost Shrine

- Role: tempo control and synergy enabler
- Cost profile: moderate support cost
- Stage fantasy: turns panic leaks into manageable waves
- Best targets: Scout groups, revive waves, heavy clumps feeding other towers
- Weak matchups: solo elite kill pressure without backup damage
- Unique ability: area pulse slows all enemies in range
- Branch fantasy:
  - `Glacier`: wider and stronger slow aura
  - `Shatter`: offensive punish window for slowed targets
- Placement guidance: central choke points, repeated overlap zones, near Barracks or Emberkeep
- Visual read: shrine profile, ice crystal crown, blue-white sacred glow
- Upgrade tier art direction:
  - T1: simple shrine base
  - T2: stronger side crystals and ritual banding
  - T3: larger ice crown and pronounced sacred platform
- Current branch sprite direction:
  - `Glacier`: broader shrine with larger side ice pillars
  - `Shatter`: sharper spear-ice crown and more aggressive crystal accents

### Coin Mill

- Role: economy engine and tempo risk tower
- Cost profile: support investment
- Stage fantasy: greed that pays off if defended well
- Best use: stable maps or early windows where the player can survive the tempo loss
- Weak matchups: fast leak-prone stages and panic placements
- Unique ability: passive coin generation plus wave-start payout
- Branch fantasy:
  - `Mint`: sustained wealth engine
  - `Tribute`: stronger burst reward and recovery value
- Placement guidance: safe backline pads, never the most exposed build slot
- Visual read: humble workshop or mill, wind-arm, coin signifier, softer palette
- Upgrade tier art direction:
  - T1: simple cottage with coin mark
  - T2: larger mill arm and reinforced workshop body
  - T3: richer merchant-house look with stronger gold signage
- Current branch sprite direction:
  - `Mint`: taller workshop with clearer coin signage and storehouse feel
  - `Tribute`: more ceremonial tax-house silhouette with banners and gold markers

### Ballista

- Role: long-range anti-elite siege answer
- Unlock: Bow Mastery level 2
- Cost profile: expensive premium tower
- Stage fantasy: deliberate elite hunter
- Best targets: Corrupted Knight, Grave Guard, Warlock, boss escorts
- Weak matchups: swarm-only waves
- Unique ability: heavy bolts pin and punish armored enemies
- Branch fantasy:
  - `Siege`: maximum elite damage and armor crack
  - `Harpoon`: longer pin and control utility
- Placement guidance: long sightlines, boss lanes, protected backline anchor pads
- Visual read: siege frame, horizontal weapon arm, heavy braces, military platform
- Upgrade tier art direction:
  - T1: field ballista
  - T2: sturdier frame and metal reinforcement
  - T3: elite siege emplacement with larger bow arm and plated base
- Current branch sprite direction:
  - `Siege`: bulkier siege bed with armored braces and heavier front arm
  - `Harpoon`: slimmer launcher silhouette with hook-tip and chain support read

### Emberkeep

- Role: burn attrition and area denial
- Unlock: Arcane Mastery level 2
- Cost profile: premium hybrid tower
- Stage fantasy: the lane becomes dangerous ground
- Best targets: clustered formations, revive units, support-backed pushes
- Weak matchups: isolated fast runners without overlap support
- Unique ability: blast applies burn over time
- Branch fantasy:
  - `Inferno`: bigger blast and hotter detonation
  - `Cinder`: longer-lasting burn attrition
- Placement guidance: clustered intersections, shrine-supported chokepoints, undead-heavy maps
- Visual read: fortified brazier tower, orange flame crown, stone fire keep
- Upgrade tier art direction:
  - T1: compact ember keep
  - T2: hotter flame core and reinforced walls
  - T3: larger infernal crown and heavier stone body
- Current branch sprite direction:
  - `Inferno`: expanded brazier mouth and taller flame plume
  - `Cinder`: lower furnace silhouette with chimney and ember vents

## Current Runtime Art Rule

- generic `T1/T2/T3` tower sprites remain the default fallback path
- when a branch is chosen, `T2/T3` now prefer branch-specific sprite files if present
- branch art should strengthen silhouette and role clarity first, and color differences second

## Summoned Defenders

These are not separate build cards, but they still need clear design rules.

### Barracks Defender

- Source: Guard Barracks
- Role: contact control and lane stall
- Readability need: should look smaller than towers but more grounded than enemies
- Base fantasy: militia or town guard
- Vanguard branch expression: heavier shield, thicker armor, sturdier stance
- Sentinel branch expression: polearm or broader reach read
- Runtime prototype rule: currently rendered as attached defender visuals around the Barracks rather than as full independent combat entities
- Tier expression:
  - T1: single militia defender
  - T2: veteran guard with clearer branch identity
  - T3: command-post garrison read with larger defender presence
- Asset family:
  - `barracks_defender_t1`
  - `barracks_defender_t2`
  - `barracks_defender_t3`
  - `barracks_defender_vanguard_t2`
  - `barracks_defender_vanguard_t3`
  - `barracks_defender_sentinel_t2`
  - `barracks_defender_sentinel_t3`
- Current runtime implementation: visual defender sprites are rendered beside the Barracks and lunge outward during attacks, while combat logic remains attached to the tower itself
- Current implementation note: the current prototype uses attached defender visuals beside the Barracks rather than fully separate spawned combat entities
- Current asset plan:
  - `T1`: militia field guard
  - `T2`: reinforced town guard
  - `T3`: captain-grade defender
  - `Vanguard`: shield-heavy bruiser visual
  - `Sentinel`: spear-leaning sentry visual
- Current prototype implementation: attached defender visuals orbit the Barracks and signal the summoned guard fantasy without adding separate combat simulation entities yet
- Sprite direction:
  - base T1-T3: shield-and-spear town guard that grows from militia to reinforced sentry
  - Vanguard T2-T3: thicker shield wall silhouette and heavier upper-body plating
  - Sentinel T2-T3: longer polearm read and wider lateral guard posture
- Runtime rule: level 1 shows one attached defender, levels 2-3 show multiple attached defenders, and branch-specific sprites take over once the branch is chosen

## Build Philosophy

Healthy build patterns should look like this:

- one cheap damage anchor plus one control anchor
- economy only after lane stability exists
- premium towers added as answers, not default spam
- branch upgrades chosen for matchup shifts, not only raw number gains

Unhealthy patterns to avoid in balance:

- Archer-only clears for late armored stages
- Coin Mill greed with no real punishment
- Frost Shrine becoming mandatory in every map
- Ballista replacing all other anti-elite answers by itself

## Counter Relationship Map

| Player buildable | Best against | Needs support against |
| --- | --- | --- |
| Archer Tower | Raider, Scout, Cult Adept | Shield Infantry, Grave Guard |
| Guard Barracks | Scout, leak control, knight stall | Warlock-supported waves |
| Mage Obelisk | armor, elite clusters | cheap rushes |
| Frost Shrine | speed waves, revive pacing | solo boss damage |
| Coin Mill | economy progression | early pressure |
| Ballista | elites, backline supports, boss escorts | swarms |
| Emberkeep | clustered waves, undead attrition | isolated runners |

## Unlock And Progression Intent

- Archer Tower and Guard Barracks should remain early comfort picks
- Mage Obelisk and Frost Shrine should feel like first strategic unlocks
- Coin Mill should tempt greed and long-term planning
- Ballista and Emberkeep should feel like real campaign milestones, not just stat upgrades

## Future Build Slots

Reserved for later once the current 7-buildable roster is stable:

- `repair post`: healing or fortification utility
- `trap glyph`: disposable path trap or rune pad
- `chapel bell`: buff or fear-control support
- `cannon cart`: explosive physical siege buildable

## Asset Notes

- tower art generation should follow this document before final upgrade-tier production
- branch-specific final art can share a base if silhouette cues still diverge clearly
- summoned defender art should be planned together with Barracks tier art, not as an afterthought
- the current prototype now includes a first-pass defender sprite family for Barracks and should use those before inventing new temporary placeholders
- Barracks defenders now have a first visual-only runtime pass; branch-specific defender variants remain a later polish pass
- attached defender visuals now exist as a first-pass implementation and should remain visually lighter than full hero or enemy sprites
- the current Barracks defender visuals are intentionally lightweight and decorative-first; if we later add true summoned defender entities, these sprites should become the visual seed rather than be discarded
