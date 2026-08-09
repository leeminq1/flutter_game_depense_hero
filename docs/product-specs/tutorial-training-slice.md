# Tutorial Training Slice

## Purpose

The tutorial teaches one rule: a wall blocks the road and a tower attacks from
behind or beside it. It must not teach the full campaign UI or ask the player to
choose between buildables.

## Training Map

- Use a dedicated 14x14 training map, not the Stage 1 map.
- Put the citadel near the center of the battlefield.
- Use one straight road from the north edge to the citadel.
- Show one north spawn marker and label it as the enemy entrance.
- Remove heroes, decorations, obstacles, alternate roads, and optional cards.

## Guided Flow

1. Camera: let the player pinch and drag once. The full battlefield remains
   visible and the player may skip this step after a short delay.
2. Wall demonstration: show only the wood-wall card, mark it `무료`, highlight
   one exact road cell, and accept placement only on that cell. Spawn one enemy
   at 1.5x speed and visibly stop it at the wall.
3. Tower pass-through demonstration: clear the sandbox, show only the archer
   card, highlight one exact road cell, and accept placement only there. Spawn
   one enemy at 1.5x speed. The enemy must keep moving through the tower while
   contact damage is shown. Supporting copy states that towers attack but do
   not block the road and lose energy when enemies pass through them.
4. Final practice: clear the sandbox and guide three exact placements in order:
   wood wall on the road, archer immediately behind the wall, and archer on the
   adjacent grass cell. Then enable `방어 시작` and spawn exactly two enemies at
   normal speed. The two towers defeat them while the wall holds the lane.
5. Recap: show the wall-block/tower-attack rule. A new-game tutorial continues
   directly to Stage 1. A title-screen replay ends with replay/home choices.

## Interaction Rules

- Tutorial construction costs zero and never consumes campaign currency.
- Only the currently required card is rendered; tabs and unrelated cards are
  hidden.
- The required card and exact target cell both pulse with a high-contrast guide.
- Invalid map taps do not build and repeat a short `빛나는 칸에 배치하세요`
  hint.
- Demonstrations are actual simulation events, not timed illustrations.
- The tutorial cannot become unwinnable due to money, selection, or placement.

## Device Acceptance

- A first-time player can finish without guessing which card or cell to use.
- Each successful action advances exactly once; invalid actions do not advance.
- The wall demo visibly stops an enemy and the tower demo visibly permits it to
  pass.
- The final practice starts only after all three guided builds exist and uses
  exactly two enemies.
- Ending the new-game flow opens Stage 1; ending menu replay offers replay/home.

