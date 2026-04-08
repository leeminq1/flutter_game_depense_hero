# Roster And Buildables

## Player Buildables: Initial Set

### 1. Archer Tower

- Role: cheap reliable single-target DPS
- Strength: early raiders and scouts
- Weakness: armored units
- Current unique ability: every third shot becomes a stronger piercing volley
- Upgrade branches:
  - Ranger: longer range and heavier crit volleys
  - Multishot: stronger split volleys into clusters

### 2. Guard Barracks

- Role: summons blocking melee defenders on the lane edge
- Strength: stall and lane control
- Weakness: vulnerable to ranged or support-heavy waves
- Current unique ability: strikes stagger targets and cleave nearby enemies
- Current visual implementation: attached defender sprites now render beside the Barracks and change with level
- Upgrade branches:
  - Vanguard: longer stagger and tougher front-line pressure
  - Sentinel: wider cleave coverage and lane reach

### 3. Mage Obelisk

- Role: magic burst and anti-armor
- Strength: shield infantry, cursed knights
- Weakness: high cost and slower cadence
- Current unique ability: chained arcane damage that jumps across clustered enemies
- Upgrade branches:
  - Storm: more chain targets and faster cadence
  - Rune: stronger armor-breaking burst

### 4. Frost Shrine

- Role: slow and control
- Strength: density management and support for other towers
- Weakness: low direct damage
- Current unique ability: area pulse that slows every enemy in range
- Upgrade branches:
  - Glacier: stronger slow and larger aura
  - Shatter: bonus damage to already slowed enemies

### 5. Coin Mill

- Role: economy support structure
- Strength: long-run stage scaling and greedy play
- Weakness: weak immediate combat contribution
- Current unique ability: passive coin generation plus wave-start bonus payout
- Upgrade branches:
  - Mint: stronger passive income
  - Tribute: better wave-start payouts and sell value

### 6. Ballista

- Role: long-range anti-elite siege tower
- Unlock: Bow Mastery level 2
- Strength: corrupted knights, shield infantry, late-wave priority targets
- Weakness: expensive, slower cadence, weaker against wide swarms
- Current unique ability: heavy bolts pin targets and punish armored enemies
- Upgrade branches:
  - Siege: harder anti-elite damage and armor cracking
  - Harpoon: longer pin duration and stronger control

### 7. Emberkeep

- Role: area denial and burn attrition tower
- Unlock: Arcane Mastery level 2
- Strength: clustered pushes, attrition waves, support-heavy formations
- Weakness: weaker front-loaded burst than mage or ballista
- Current unique ability: detonates an ember burst that applies burn over time
- Upgrade branches:
  - Inferno: larger blast radius and hotter burn damage
  - Cinder: longer burn duration and better crowd attrition

## Future Buildables

- Healing shrine or repair post
- Trap pad or rune tile

## Early Enemy Roster

### Raider

- Fast basic humanoid
- Low HP, low armor
- Teaches core targeting
- Current special ability: enrages below half health

### Scout

- Very fast path runner
- Low HP
- Punishes slow setup
- Current special ability: dodges the first physical hit

### Banner Captain

- Early bandit support leader
- Buff-centric pressure amplifier
- Encourages support-target priority before the frontline snowballs
- Current special ability: periodically grants nearby bandit-family allies bonus speed and base damage

### Wolf Scout

- Beastfolk speed variant
- Faster than the base scout and harder to clean up late
- Sharpens the lane-coverage check in early-mid stages
- Current special ability: dodges the first physical hit and gains a permanent speed boost below `60%` health

### Shield Infantry

- Moderate speed
- Armor resistance
- Encourages magic or armor-breaking answers
- Current special ability: reduces physical damage taken

### Cult Adept

- Support enemy
- Buffs nearby units or debuffs towers
- Should appear in protected wave compositions
- Current special ability: periodically hastes nearby allies

### Skeleton Infantry

- Durable attrition unit
- Moderate speed, persistent pressure
- Current special ability: revives once with partial health

### Bone Archer

- Undead skirmisher
- Extends wave length without needing a giant HP pool
- Makes cleanup and corpse control matter earlier
- Current special ability: spawns one normal skeleton on death

### Plague Bearer

- Undead sustain support
- Turns fair undead fights into longer attrition checks
- Should appear behind mixed undead and elite pressure
- Current special ability: periodically heals nearby undead and grants short damage reduction

### Grave Guard

- Tankier undead elite
- High HP, strong lane pressure
- Current special ability: resists slows and shrugs off heavy control effects

### Corrupted Knight

- Elite armored humanoid
- High threat, lower count
- Current special ability: charges harder after being wounded

### Hex Sniper

- Late support disruptor
- Protects elite escorts instead of front-lining itself
- Raises the cost of ignoring backline ranged support
- Current special ability: periodically grants a ward to itself and the highest-priority nearby ally

### Warlock

- Late-game support / elite caster
- Mix of buff, summon, or ranged spell pressure
- Current special ability: periodically wards allies and summons reinforcements
- Current art note: second-pass mantle and glow polish makes the support read more distinct from Cult Adept

### Bastion Priest

- Late elite support
- More durable than other support casters and built to keep elite waves alive
- Should appear in smaller counts but high-protection compositions
- Current special ability: periodically heals the highest-priority elite ally and refreshes a ward; self-heals if no elite ally is nearby

### Bastion Overlord

- Final campaign boss
- Huge HP pool, slow but relentless advance
- Current special ability: shifts phases, pulses self-warding shields, and summons escorts mid-fight
- Current art note: second-pass obsidian shoulder frame strengthens the fortress-boss silhouette

## Faction Pacing

- Stages 1-5: bandit emphasis with Banner Captain support entering at stage 4
- Stages 6-10: bandit speed pressure widens through Wolf Scout and the first cult support
- Stages 11-15: undead attrition broadens through Bone Archer spillover and armored crossover
- Stages 16-20: undead pressure takes over and Plague Bearer sustain joins Grave Guard front-lining
- Stages 21-25: cursed bastion waves add Hex Sniper ward support behind elite escorts
- Stages 24-29: Bastion Priest joins the late elite-support stack without changing stage 30 boss ownership
- Stage 30 finale: Bastion Overlord arrives in the last wave with escort summons and phase changes

## Real-Time Placement Rule

- Players can build during waves, so buildables must have clear placement cost and instant feedback.
- Guard Barracks and Frost Shrine help active wave correction.
- Economy structures should remain risky to place mid-wave.
- Ballista and Emberkeep should appear in the build bar as locked cards before they are unlocked so the player understands the meta goal.

## Combat Readability

- Projectile, beam, pulse, and impact visuals should stay lightweight so Flame rendering stays responsive on larger waves.
- Tower abilities and enemy traits must be readable without depending on heavy sprite FX or shader work.
- Guard Barracks now uses lightweight defender-side sprites instead of introducing separate defender entities too early.
