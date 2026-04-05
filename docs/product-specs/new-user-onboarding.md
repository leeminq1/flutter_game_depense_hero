# New User Onboarding

## Goal

Teach the first-session player placement, wave pressure, and upgrades with minimal interruption.

## First-Run Flow

1. Show a short start screen with one clear call to action.
2. Start on a beginner-friendly map with pre-highlighted placement nodes.
3. Teach placement with a single tower.
4. Teach wave start and enemy path readability.
5. Introduce one upgrade choice before complexity spikes.
6. End with a summary that explains why the player won or lost.

## Current First Playable Implementation

The current first-playable onboarding pass uses stage-aware tutorial cards instead of heavy modal interruptions.

- Stage 1: teach build-card selection, slot placement, wave start, and tower tapping
- Stage 2: teach early spending, second-tower timing, and first upgrade timing
- Stage 3: teach armor counterplay with Mage against Shield Infantry
- Stage 4: teach control timing and lane stabilization with Frost support
- Stage 5: teach crest-stage pacing plus the first safe Coin Mill timing

Implementation notes:

- tutorial guidance appears only for stages `1-5`
- guidance stays lightweight and lives in the battle HUD layer
- tutorial cards now behave like short checklist guidance instead of plain hint text
- tutorial can be dismissed and that dismissal is persisted locally
- tutorial text should reinforce the actual stage objective, not compete with it
- settings now include a local tutorial reset path so first-run guidance can be restored without wiping save data

## Success Criteria

- The player can place a tower without reading a long tutorial.
- The player understands the base/core they must defend.
- The player sees one example of why upgrade timing matters.
- The player reaches Stage 5 understanding that different enemy roles require different tower answers.
