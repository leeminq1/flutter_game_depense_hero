# Enemy Roster Bible

## Purpose

Lock the detailed role, silhouette, pacing, and encounter intent for each enemy in the 30-stage campaign.

This document exists so future art generation, balance passes, wave authoring, and boss expansion all pull in the same direction.

## Core Enemy Families

The campaign uses four overlapping pressure families:

- `bandit pressure`: speed, greed punishment, early readability
- `cult support`: buffing, wave shape manipulation, magic pressure
- `undead attrition`: revive, stubborn frontline pressure, tempo drain
- `bastion elite`: armor, anti-control resistance, late-game stat and mechanic checks

## Readability Rules

Every enemy should answer these three questions at a glance:

1. Is it fast, tanky, or supportive?
2. Is it physical, cursed, or armored?
3. Should the player kill it first?

Visual implications:

- fast enemies need a slimmer silhouette and forward-leaning pose
- tanks need broad shoulders, shields, or heavy torso mass
- support enemies need staff, lantern, spell glow, or ritual signifiers
- elites need stronger headpiece, armor trim, and color separation

## Wall Interaction Roles

The current fortress-design pass groups enemies by how they treat walls and towers:

| Role | Enemies | Wall Behavior | Tower Contact |
| --- | --- | --- | --- |
| Fast pressure | Scout, Wolf Scout, Bone Archer, Hex Sniper | always hits the wall ahead, low structure damage | low chip damage while passing |
| Mixed breaker | Raider, Skeleton, Cult Adept, Banner Captain, Plague Bearer, Warlock, Bastion Priest | always hits the wall ahead, medium structure damage | medium contact damage |
| Force breaker | Shield Infantry, Grave Guard, Corrupted Knight, Bastion Overlord | always break the wall ahead | high contact damage |

All normal leaks currently deal `1` citadel damage; the citadel has `3` HP. This keeps failure readable and makes wall placement matter immediately.

## Roster Detail

### Raider

- Faction: bandit
- Stage entry: 1
- Threat job: baseline lane pressure and greed punishment
- Movement read: quick jog, aggressive forward posture
- Defensive profile: low health, low armor
- Offensive profile: basic chip damage to the core if ignored
- Special trait: enrages below half health and briefly speeds up
- Player lesson: cheap single-target towers solve raiders efficiently, but greedy economy openings can leak them
- Visual recipe: hood or leather cap, light chest gear, short blade or hatchet, warm brown and red accents
- LPC direction: human or orc variant is fine, but avoid heavy armor layers

### Scout

- Faction: bandit
- Stage entry: 2
- Threat job: outruns slow setups and pokes weak coverage
- Movement read: narrow body, fast gait, ranged light-weapon silhouette
- Defensive profile: very low health
- Offensive profile: low direct threat per unit, high leak threat in groups
- Special trait: dodges the first physical hit
- Player lesson: frost and barracks stabilize lanes that archers alone may miss
- Visual recipe: wolf-like or light rogue silhouette, short cloak, compact bow or knives, minimal armor
- LPC direction: wolf head or light hooded scout works well

### Banner Captain

- Faction: bandit support leader
- Stage entry: 4
- Threat job: turns early mixed waves into coordinated pushes
- Movement read: leader silhouette, spear or banner read, brighter crest accent
- Defensive profile: light to medium
- Offensive profile: moderate by itself, high indirect pressure through buffs
- Special trait: every 3.2 seconds grants nearby bandit-family allies `+15%` speed and `+1` base damage for `1.8s`
- Player lesson: support leaders must be picked off before the frontline multiplies in value
- Visual recipe: leather captain, banner pole or spear, red hood mark or plume, commanding upper-body read
- LPC direction: captain hat plus plume is preferred over generic bandit headwear

### Wolf Scout

- Faction: bandit beastfolk skirmisher
- Stage entry: 6
- Threat job: creates a sharper speed-check variant than the base scout
- Movement read: beast head, narrow runner body, quick ranged silhouette
- Defensive profile: low health with one-time evasion
- Offensive profile: low per-unit damage, high leak pressure
- Special trait: dodges the first physical hit and gains a permanent speed boost below `60%` health
- Player lesson: the player needs layered coverage, not only one strong lane anchor
- Visual recipe: wolf head, light leather, slim bow read, gray-brown fur accents
- LPC direction: use the beast head as the silhouette anchor and keep the torso mass light

### Shield Infantry

- Faction: bandit to bastion transitional frontline
- Stage entry: 4
- Threat job: teaches armor checks and stalls physical towers
- Movement read: broad silhouette, centered shield face, slower cadence
- Defensive profile: medium health, strong physical mitigation
- Offensive profile: moderate
- Special trait: reduces incoming physical damage
- Player lesson: mage, burn, and armor-break become more valuable
- Visual recipe: heater shield, closed helm or headwrap, layered torso cloth under armor
- LPC direction: shield pattern is important for role clarity

### Cult Adept

- Faction: cult
- Stage entry: 8
- Threat job: turns simple waves into priority-target puzzles
- Movement read: rearline caster, robe-heavy lower silhouette, glowing accent
- Defensive profile: fragile if exposed
- Offensive profile: indirect; amplifies allies more than raw damage
- Special trait: periodically hastes nearby allies
- Player lesson: support enemies must be focused before they multiply total wave pressure
- Visual recipe: robed torso and legs, occult sash, lantern or staff, purple accents
- LPC direction: must always look clothed and ceremonial, never like a peasant base body

### Skeleton Infantry

- Faction: undead
- Stage entry: 11
- Threat job: soak attrition damage and lengthen fights
- Movement read: bony, upright, simple weapon read
- Defensive profile: moderate effective health because of revive
- Offensive profile: steady, not explosive
- Special trait: revives once with partial health
- Player lesson: single-shot high damage is less efficient than sustained coverage
- Visual recipe: clear skull read, worn scraps or rusted fragments, pale desaturated palette
- LPC direction: keep silhouette simple so revive read stays clear

### Bone Archer

- Faction: undead skirmisher
- Stage entry: 12
- Threat job: extends attrition waves and punishes weak cleanup
- Movement read: narrow skeleton with clear bow silhouette
- Defensive profile: low to medium
- Offensive profile: low direct threat, high attrition value
- Special trait: spawns one normal `Skeleton Infantry` when destroyed
- Player lesson: cleanup and corpse-control matter once the undead roster widens
- Visual recipe: skeleton bowman, worn scraps, pale bone with dark ranged prop
- LPC direction: preserve the bow read even at live battlefield scale

### Plague Bearer

- Faction: undead support
- Stage entry: 17
- Threat job: sustains undead pushes without needing a boss-tier healer
- Movement read: hooded plague silhouette, censer or ritual staff, hanging cloth mass
- Defensive profile: medium
- Offensive profile: indirect; converts already-good pushes into longer fights
- Special trait: every 4.0 seconds heals nearby undead for `8%` max HP and grants `12%` damage reduction for `1.5s`
- Player lesson: sustained support must be answered before elite damage checks become unfair
- Visual recipe: plague hood, censer, bone-green cloth accents, sickly support aura
- LPC direction: use cloth and prop language to separate it from both Warlock and Cult Adept

### Grave Guard

- Faction: undead elite
- Stage entry: 18
- Threat job: front-line anchor that absorbs control and buys time for casters
- Movement read: heavy, squared, shielded or plated undead frame
- Defensive profile: high health, control resistance
- Offensive profile: moderate but relentless
- Special trait: shrugs off slows and staggers more than other units
- Player lesson: the player needs real damage commitment, not just tempo control
- Visual recipe: cemetery knight silhouette, slab-like shoulders, grave-metal palette, muted green or bone accent
- LPC direction: bulk and torso mass matter more than facial detail

### Corrupted Knight

- Faction: bastion elite
- Stage entry: 15
- Threat job: punishes shaky single-lane answers and tests anti-elite coverage
- Movement read: armored charger silhouette, cape or tabard, strong helm read
- Defensive profile: high armor, high threat
- Offensive profile: heavy burst if it reaches the core
- Special trait: enters a more dangerous charge state after being wounded
- Player lesson: the player must decide whether to burst it down or lock it early
- Visual recipe: dark plate, cursed red or ember trim, imposing shoulders, elite sword silhouette
- LPC direction: use heavier layering than shield infantry and a cleaner elite palette

### Hex Sniper

- Faction: cursed ranged disruptor
- Stage entry: 21
- Threat job: hardens elite escorts and forces cleaner target priority
- Movement read: narrow hood, crossbow silhouette, occult accent
- Defensive profile: low to moderate
- Offensive profile: indirect but tactically expensive if ignored
- Special trait: every 5.0 seconds grants `1` ward charge to itself and the highest-priority nearby ally
- Player lesson: support that protects elites can be as dangerous as the elites themselves
- Visual recipe: dark hood, crossbow, violet-green focal detail, cursed support posture
- LPC direction: keep the ranged prop and hood read stronger than the robe mass

### Warlock

- Faction: late cult-bastion support
- Stage entry: 23
- Threat job: makes endgame waves feel alive and compound in difficulty
- Movement read: rearline caster with tall headpiece or high mantle and clear glow accent
- Defensive profile: low to moderate
- Offensive profile: indirect but extremely high strategic value
- Special trait: wards allies and summons reinforcements
- Player lesson: kill the enabler or the lane snowballs out of control
- Visual recipe: full robe, occult mantle, staff or tome, orange-violet energy contrast
- LPC direction: robe and shoulders are mandatory; never leave leg or torso reads underdressed

### Bastion Priest

- Faction: bastion elite support
- Stage entry: 24
- Threat job: sustains late elite pushes and refreshes the line at the worst moment
- Movement read: plated cleric silhouette, mace or ritual staff, pale cloth focal point
- Defensive profile: medium-high for a support unit
- Offensive profile: indirect; preserves elite uptime more than dealing damage itself
- Special trait: every 4.8 seconds heals the highest-priority elite ally for `14%` max HP and refreshes `1` ward charge; if no elite ally is nearby it self-heals for half value
- Player lesson: late-game support cannot be evaluated only by raw HP or speed
- Visual recipe: plated cleric, white-gold cloth, ritual mace, bastion authority read
- LPC direction: combine a plated torso with a bright cleric cloth accent so it does not collapse into normal infantry

### Bastion Overlord

- Faction: final boss
- Stage entry: 30 final wave
- Threat job: campaign capstone and knowledge check
- Movement read: huge fortress-knight silhouette, phase aura, command presence
- Defensive profile: boss health pool, phase shields, escort summons
- Offensive profile: overwhelming if the player cannot maintain late-wave structure
- Special trait: phase transitions, self-warding pulse, escort summons, ally acceleration support
- Player lesson: the full campaign toolkit matters, not one overpowered tower
- Visual recipe: massive armored tyrant, infernal or royal crest language, heavy red and obsidian palette
- LPC direction: use the richest layer stack in the roster and preserve a clean crown or horn focal point

## Stage Pacing By Bracket

### Stages 1-5

- primary pressure: Raider and Scout
- support pressure: Shield Infantry plus first Banner Captain rally window
- player fantasy: "I can stabilize this lane if I place smartly"

### Stages 6-10

- primary pressure: bandits plus Wolf Scout speed checks
- support pressure: Banner Captain and first Cult Adept support
- player fantasy: "I need to identify priority targets instead of only building more DPS"

### Stages 11-15

- primary pressure: Skeleton Infantry attrition, Bone Archer spillover, and armored crossover
- support pressure: revive mechanics and lane fatigue
- player fantasy: "The same solution from stage 3 is no longer enough"

### Stages 16-20

- primary pressure: Grave Guard frontline with knight backing
- support pressure: Plague Bearer sustain and cult overlap
- player fantasy: "My tower combinations and upgrade choices matter"

### Stages 21-29

- primary pressure: ward-heavy bastion compound waves
- support pressure: Hex Sniper, Warlock, and Bastion Priest stacking on elite escorts
- player fantasy: "Every leak came from a real tactical problem"

### Stage 30

- primary pressure: Bastion Overlord with layered support
- player fantasy: "This is the full exam for the whole campaign"

## Counter Mapping

| Enemy | Best answers | Risky answers |
| --- | --- | --- |
| Raider | Archer, Barracks | greedy early Coin Mill openings |
| Scout | Frost, Barracks, cheap coverage | slow single-target-only plans |
| Banner Captain | Archer pickoff, Ballista, Barracks stall | letting buff auras sit behind the frontline |
| Wolf Scout | Frost, layered cheap coverage, Barracks | one-lane-only single-target plans |
| Shield Infantry | Mage, Emberkeep, Ballista | Archer-heavy lines |
| Cult Adept | Archer focus, Ballista pickoff | ignoring backline support |
| Skeleton Infantry | Frost plus sustained DPS | overreliance on one-shot damage |
| Bone Archer | sustained splash cleanup, Frost, Archer support | counting on one clean kill per body |
| Plague Bearer | Ballista pickoff, focused burst, layered mage damage | slow attrition into healing loops |
| Grave Guard | Ballista, Mage, layered DPS | pure slow-control plans |
| Corrupted Knight | Ballista, Barracks stall plus burst | weak anti-elite coverage |
| Hex Sniper | Ballista pickoff, fast Archer focus | leaving support alive behind elite wards |
| Warlock | Ballista pickoff, Archer support focus | allowing summon cycles to repeat |
| Bastion Priest | Ballista, burst windows, anti-support focus | splitting damage across too many elites |
| Bastion Overlord | full combined roster | one-note builds |

## Expansion Notes

- `banner captain`, `wolf scout`, `bone archer`, `plague bearer`, `hex sniper`, and `bastion priest` are now part of the live roster
- future enemy slots should expand with the same family logic instead of replacing these roles

## Asset Notes

- enemy sprite generation should follow this document before balance tuning
- support enemies need especially strong silhouette cues because they define target priority
- if a later balance pass changes an enemy role, update this bible before regenerating art

## Current Sprite Review Priorities

Reviewed on `2026-04-04` with multi-agent feedback and a local polish pass layered on top of the LPC-derived PNGs.

### Strongest Current Reads

- `Corrupted Knight`: strongest non-boss elite silhouette, good horned helm and tank pressure read
- `Bastion Overlord`: strongest focal point, boss crown and infernal color read work well
- `Raider`: already readable as an early aggressive bandit

### Highest-Priority Weak Reads

- `Warlock`: still the most important future LPC regeneration target because late-game enabler status needs an even clearer headpiece and magical focal prop
- `Cult Adept`: improved, but still wants a more ceremonial support-caster read than a generic robed unit
- `Grave Guard`: improved slab and trim read, but should gain even more torso mass in a later pass
- `Scout`: speed read is now solid enough for production, but it remains the lightest candidate for a future personality pass if the bandit faction needs more flair

### Current Production Rule

- Keep the current polished PNG set in use for runtime readability
- Full LPC regeneration is now unblocked again through the Node-based exporter
- Base enemy PNGs now come from the LPC split ZIP `standard/walk/down/5.png` so the base frame matches the walk cycle
- Keep `walk_02` and `walk_03` sourced from `standard/walk/down/3.png` and `standard/walk/down/7.png`
- Use further LPC regeneration later for `Warlock`, `Cult Adept`, and `Grave Guard` first if another silhouette jump is needed
- Keep the current `Shield Infantry` batch asset unless a future battlefield camera change makes the shield read less prominent
- Preserve faction palette discipline when rerendering so the campaign still feels coherent

### Current Third-Pass Outcome

The first post-fix targeted LPC rerender was applied to:

- `Cult Adept`
- `Grave Guard`
- `Warlock`

Current result:

- `Warlock` now separates more clearly from `Cult Adept` through a stronger hat and caster silhouette
- `Cult Adept` now reads more like a ritual support unit than a generic robe silhouette
- `Grave Guard` now keeps a heavier armored-undead tank read while staying distinct from `Corrupted Knight`
- the current asset pass intentionally pushes `cult_adept` toward ritual-support cues and `warlock` toward late-game caster authority so they do not collapse into one shared robe silhouette

### Current Fourth-Pass Outcome

Reviewed on `2026-04-04` through a focused scout / tank pass with multi-agent input plus local preview review.

Applied to:

- `Scout`
- `Shield Infantry`

Current result:

- `Scout` now reads more clearly as a fast ranged skirmisher through a lighter teen body silhouette, forest hood, and smaller torso mass
- `Shield Infantry` now lands cleanly as a shield-first frontline unit through a stronger green kite-shield read and a more disciplined legion-helm profile
- the current batch is good enough to keep in production without blocking tower or environment art follow-up

## Current Second-Pass Polish Notes

These notes reflect the current post-LPC polish pass applied after multi-agent silhouette review.

- `Raider`: off-hand hatchet cue was strengthened so the early melee threat reads more aggressively
- `Scout`: scarf and lighter motion cue were added so the sprite reads faster and less planted
- `Shield Infantry`: shield face was strengthened to center the tank read
- `Cult Adept`: robe hem, sash, and ritual glow were reinforced so support-caster priority is clearer
- `Skeleton Infantry`: a small worn scrap was added so the unit feels less placeholder-clean
- `Grave Guard`: shoulder mass and green grave-metal trim were strengthened
- `Corrupted Knight`: shoulder width and darker rear mass were increased to separate it from normal infantry
- `Warlock`: mantle and bright staff-glow read were strengthened so it separates from Cult Adept
- `Bastion Overlord`: obsidian shoulder frame was reinforced to push the fortress-boss silhouette

## Current Sprite Review Notes

This review was captured after a multi-agent pass over the current enemy sprite set.

Strong current reads:

- `Corrupted Knight` already reads as the clearest non-boss elite because the horned helm and dark mass separate it well from the rest of the roster
- `Bastion Overlord` already has a strong focal crown and good final-boss presence

Highest-priority polish targets:

- `Warlock`: must look more distinct from Cult Adept through taller mantle, stronger caster focal point, and brighter staff or tome glow
- `Cult Adept`: needs a clearer support-caster read through robe hem, sash, and ritual prop emphasis
- `Shield Infantry`: needs a more dominant forward shield read and less exposed-leg contrast so the tank role lands faster
- `Grave Guard`: needs broader shoulder mass and stronger grave-metal or green-bone trim to feel like an undead tank instead of dark infantry
- `Scout`: needs a slimmer, more forward-leaning runner silhouette

Secondary polish targets:

- `Raider`: reinforce knife or hatchet cue
- `Skeleton Infantry`: add one worn scrap or rusted badge so it feels less placeholder-like
- `Bastion Overlord`: broaden fortress-like shoulder framing in a later pass
