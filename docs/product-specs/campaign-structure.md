# Campaign Structure

## Campaign Shape

The campaign remains a `30-stage` progression path. `Stage` and `Wave` are the player-facing terms; `Act` is a five-Stage campaign chapter used for long-term pacing.

Final structure:

- `30 Stages`
- `6 Acts`
- `5 Stages per Act`

This preserves the content volume and progression value while keeping battle UI terminology simple.

## Development Unlock

Public builds keep authored progression enabled. Local content-review builds
can temporarily unlock all `30` stages through
`lib/data/persistence/progression_dev_flags.dart`.

Reason:

- map and wave authoring is being validated across the full campaign
- the developer needs to jump directly into any Stage without clearing the
  previous chain first
- this is a content-review shortcut only; it must not be treated as final
  player progression

Release switch:

```dart
const bool kUnlockAllCampaignStagesForDevelopment = false;
```

Runtime behavior when temporarily enabled:

- both native/local progress and web/in-memory progress report every Stage as
  unlocked
- existing stars, clears, currency, and reward records are not faked or
  overwritten
- clearing a Stage still writes normal completion records, so balance testing
  remains meaningful

Release check:

1. Confirm `kUnlockAllCampaignStagesForDevelopment` is `false`.
2. Run the progress-store tests and a quick campaign UI smoke test.
3. Confirm Stage 1 is available by default and later stages require the authored
   previous-stage/star/meta requirements again.

## Act Summary

| Act | Name | Stage Range | Learning Goal | Main Pressure |
| --- | --- | --- | --- | --- |
| 1 | Forest Approaches | 1-5 | Learn citadel defense and two-front stabilization | Bandit speed and basic armored checks |
| 2 | Crossroads War | 6-10 | Learn three-front prioritization and support denial | Bandits plus early cult support |
| 3 | Grave March | 11-15 | Learn revive cleanup and attrition control | Undead from vertical pressure fronts |
| 4 | Chapel Siege | 16-20 | Learn anti-support discipline under split pressure | Undead elites, cursed knights, and healing support |
| 5 | Bastion Front | 21-25 | Learn full four-front control and ward management | Bastion elite overlap on all fronts |
| 6 | Throne March | 26-30 | Final exam for the full roster and economy discipline | All factions plus Bastion Overlord |

## Act Details

### Act 1: Forest Approaches

Intent:

- teach the citadel-centered layout
- teach that the player cannot solve every problem with one-lane logic
- introduce the first safe `economy vs defense` tradeoff
- prove that walls are required because towers no longer erase enemies before contact
- keep enemy randomness previewed through Wave threat tags instead of hidden spawns

Recommended Stage rhythm:

| Stage | Wave Count | Active Front Pattern | Special Learning Goal | Final Breach |
| --- | --- | --- | --- | --- |
| 1 | 3 | North only | 성벽으로 늦추기 | north-lane breach |
| 2 | 4 | North -> North+East | 타워 사거리 겹치기 | two-front breach |
| 3 | 4 | North -> North+East | 영웅 방어 위치와 첫 장갑 체크 | two-front armor test |
| 4 | 4 | North+East | first design-card Stage | two-front design test |
| 5 | 4 | North -> North+East | early fortress-design exam | Banner Captain two-front breach |

### Act 2: Crossroads War

Intent:

- move from split attention to real prioritization
- teach that support enemies can be more dangerous than the frontline

Main additions:

- Wolf Scout
- Cult Adept
- denser Shield Infantry windows

Recommended siege rhythm:

| Siege | Cycle Count | Active Front Pattern | Special Learning Goal | Final Breach |
| --- | --- | --- | --- | --- |
| 6 | 4 | North -> North+West -> North+West+East | first true three-front prioritization | 3-front armor push |
| 7 | 4 | West+East pressure with delayed North | first support denial | Cult Adept backline finale |
| 8 | 4 | East-heavy start, then split 3-front | armor plus support together | leader-backed split breach |
| 9 | 4 | rotating 3-front emphasis | planning from telegraphs | rotating pressure capstone |
| 10 | 4 | four-front finish | first leader-heavy climax | four-front captain finale |

### Act 3: Grave March

Intent:

- force cleanup discipline
- make revive and attrition feel different from simple rush pressure

Main additions:

- Skeleton
- Bone Archer
- Grave Guard
- Plague Bearer

Recommended siege rhythm:

| Siege | Cycle Count | Active Front Pattern | Special Learning Goal | Final Breach |
| --- | --- | --- | --- | --- |
| 11 | 4 | North only -> North+South | vertical pressure read | revive-focused north breach |
| 12 | 4 | North+South every cycle | cleanup discipline | Bone Archer crossfire breach |
| 13 | 4 | North+South plus light East | attrition plus armor | mixed undead armor push |
| 14 | 4 | strong North, delayed South | uneven front density | Grave Guard intro breach |
| 15 | 4 | full North+South stress test | revive cleanup exam | undead attrition capstone |

### Act 4: Chapel Siege

Intent:

- make anti-support targeting mandatory
- teach that elite overlap matters more than raw tower count

Main additions:

- Corrupted Knight
- Hex Sniper
- Warlock

Recommended siege rhythm:

| Siege | Cycle Count | Active Front Pattern | Special Learning Goal | Final Breach |
| --- | --- | --- | --- | --- |
| 16 | 4 | North+East split | anti-support basics | Knight-led split breach |
| 17 | 4 | East-heavy start, then 3-front | ranged support focus | Hex Sniper reveal |
| 18 | 4 | 3-front sustained pressure | support overlap discipline | Warlock pressure spike |
| 19 | 4 | rotating 3-front with elite overlap | split-priority under stress | knight plus support breach |
| 20 | 4 | all four fronts in later cycles | full anti-support exam | cursed-support capstone |

### Act 5: Bastion Front

Intent:

- normalize full four-front simultaneous pressure
- make ward and elite sustain the defining tactical problem

Main additions:

- Bastion Priest
- cross-front composition mixing

Recommended siege rhythm:

| Siege | Cycle Count | Active Front Pattern | Special Learning Goal | Final Breach |
| --- | --- | --- | --- | --- |
| 21 | 5 | 3-front to 4-front escalation | full-board tower networking | first 5-cycle siege |
| 22 | 5 | four-front every late cycle | ward and sustain management | Bastion Priest intro |
| 23 | 5 | uneven front spikes | rebuild discipline | elite sustain breach |
| 24 | 5 | constant four-front overlap | support sniping under load | mixed sustain capstone |
| 25 | 5 | hardest preboss bastion siege | late-act mastery check | bastion sustain finale |

### Act 6: Throne March

Intent:

- demand full roster mastery
- culminate in a boss-led final breach

Boss:

- `Bastion Overlord` on Siege 30

Recommended siege rhythm:

| Siege | Cycle Count | Active Front Pattern | Special Learning Goal | Final Breach |
| --- | --- | --- | --- | --- |
| 26 | 5 | four-front from cycle 2 onward | no weak-side openings | elite overlap exam |
| 27 | 5 | heavy South and East bias | support burst priority | priest-backed breach |
| 28 | 5 | rotating four-front pressure | telegraph mastery | late mixed-roster breach |
| 29 | 5 | strongest non-boss siege | economy and recovery exam | preboss gauntlet |
| 30 | 5 | cycles 1-4 full normal pressure | final roster exam | Bastion Overlord boss breach |

## Unlock Structure

Acts are gated by `Siege Tokens`.

| Unlock | Requirement |
| --- | --- |
| Act 2 | 5 Siege Tokens |
| Act 3 | 12 Siege Tokens |
| Act 4 | 22 Siege Tokens |
| Act 5 | 35 Siege Tokens |
| Act 6 | 50 Siege Tokens |

## Siege Objective Structure

Every siege should ship with one required clear condition and two optional mastery objectives.

Recommended objective families:

- clear the siege
- keep citadel HP above threshold
- build at most `X` structures
- do not sell more than `Y` structures
- use at least one named tower family
- preserve a specific outer relay or support node

## Final Breach Rule

Every act should end with a more memorable final breach.

Examples:

- Siege 5: first coordinated four-front pressure
- Siege 10: first leader-heavy finale
- Siege 15: undead attrition capstone
- Siege 20: late support overlap stress test
- Siege 25: bastion sustain capstone
- Siege 30: Bastion Overlord final siege

## Endless Mode Position

Endless survival is not the main progression mode.

Rule:

- unlock only after a meaningful campaign milestone
- use the same battlefield language and front identity
- reward mastery, not the best progression efficiency
