# Completion Checklist

Before finalizing non-trivial code changes:

- Update affected product/design/exec-plan docs if gameplay behavior, economy, map authoring, or player-facing rules changed.
- Run targeted tests for touched behavior, then broader `flutter test` when feasible.
- Run `flutter analyze` or report clearly if not run.
- For UI/gameplay visual changes, prefer launching/capturing the app when feasible; at minimum inspect affected render/layout code and tests.
- Report exact verification performed and any residual ambiguity or assumptions.