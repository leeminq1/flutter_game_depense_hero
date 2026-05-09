# Style And Conventions

- Follow Flutter lints from `package:flutter_lints/flutter.yaml`.
- Keep changes surgical and data-driven; prefer existing model definitions and renderer helpers over new abstractions.
- Dart style uses descriptive lowerCamelCase members, UpperCamelCase classes/enums, immutable model classes where practical, and `const` constructors/widgets when possible.
- Flutter widgets should observe state and send commands; combat behavior belongs in `lib/game` runtime/controller code.
- Specs/docs are system of record for player-facing behavior. Update relevant product/design docs when changing gameplay, economy, map semantics, or combat readability.
- Avoid unrelated formatting churn and do not edit generated files unless regenerating intentionally.