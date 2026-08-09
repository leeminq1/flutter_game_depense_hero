# Tutorial Training Slice Rebuild Plan

**Goal:** Replace the broad eight-step tutorial with a deterministic single-lane
training sandbox that teaches wall blocking and tower attacking through real
player actions and real enemy simulation.

**Architecture:** Keep campaign combat data unchanged. `TutorialStageDefinition`
owns the training map and target cells. `TutorialDirector` owns the finite state
machine and exact accepted action. `DepenseGame` enforces free targeted placement
and runs the two demonstrations/final wave. Flutter overlays render only the
required build card and concise instruction, while the Flame world renders the
precise target-cell guide.

## Task 1: Lock the map and state machine with tests

- Update tutorial stage tests for one north route, central citadel, no props,
  exact lesson/practice cells, and a two-enemy final wave.
- Update director tests for camera -> wall placement -> wall block observation ->
  road-tower placement -> pass-through observation -> three guided final builds
  -> two-enemy defense -> recap.
- Verify wrong card/cell events are ignored.

## Task 2: Implement the training domain

- Replace the inherited Stage 1 tutorial definition with the dedicated map.
- Add typed required build and target-cell data to tutorial snapshots/events.
- Make demonstration completion event-driven instead of timer-driven.

## Task 3: Implement precise UI and construction rules

- Render one free required card and hide tabs/unrelated choices.
- Auto-select and restrict builds to the required kind and exact cell.
- Draw a pulsing target cell and concise placement hint in the game world.
- Disable tutorial hero placement and coin spending.

## Task 4: Implement real demonstrations and final practice

- Clear/reset the sandbox between wall and tower demonstrations.
- Spawn one 1.5x demonstration enemy for each lesson and report the observed
  block/pass event to the director.
- Spawn exactly two normal-speed final enemies after all three guided builds.
- Preserve the existing new-game and menu-replay completion routes.

## Task 5: Verify on the Android build

- Run focused tutorial tests, the full Flutter test suite, `flutter analyze`,
  `git diff --check`, and `flutter build apk --debug`.
- Install/run the new debug build on the connected device for user acceptance.

