# Reliability

## Goals

- The game should recover cleanly from asset load failures where possible.
- Save data should be versioned from the start.
- Combat simulation bugs should be debuggable through logs or deterministic test inputs.

## Reliability Rules

- Version every persisted schema.
- Keep runtime session state separate from permanent player progress.
- Add debug instrumentation for wave spawn, targeting, damage, and death events.
- Treat content definition validation as a build-time concern, not only a runtime concern.
- Persist progress only at safe checkpoints: stage clear, reward claim, upgrade purchase, settings change.
- Make reward-granting idempotent so app restarts do not duplicate currency or unlocks.
- Audio services should fail soft: a missing sound or playback error must not crash or stall gameplay.

## Early Failure Cases To Design For

- Missing atlas frame or wrong sprite naming
- Bad wave definition that spawns impossible counts
- Save file shape drift after feature updates
- Overlay/game desynchronization during pause or resume
- Crash or force-close between ad reward completion and reward persistence
- Dozens of simultaneous hit sounds causing player churn, audio clipping, or frame pacing issues
