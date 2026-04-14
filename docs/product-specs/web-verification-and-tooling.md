# Web Verification And Tooling

## Purpose

The new mode must be testable through Flutter Web and browser automation so gameplay and UI regressions can be caught before mobile-only checks.

## Required Tools

Use these local tools:

- Flutter Web server
- `playwright` skill workflow
- Playwright CLI through `npx`

## Current Web Status

Confirmed locally on `2026-04-14`:

- `flutter analyze` passes
- `flutter build web` succeeds
- `flutter build web --wasm` succeeds
- the app now routes web builds to an in-memory progress store instead of the native Isar path
- `npx --yes --package @playwright/cli playwright-cli` is available for browser automation
- portrait screenshots were captured at:
  - `360 x 800`
  - `412 x 915`
  - `768 x 1024`
  - `834 x 1194`
- landscape verification confirms the portrait-only guard renders instead of gameplay

Current limitation:

- the QA overlay and debug controls are still a future milestone
- without that overlay, Web validation is still strongest for launch, layout, orientation, and screenshot review rather than full gameplay assertions

## Flutter Web Run Command

Recommended local run command:

```powershell
flutter run -d web-server --web-port 7357
```

Why this mode:

- does not require Playwright to control a browser instance already owned by Flutter
- lets Playwright open the app like a normal website

## Required Viewport Rule

This project targets `mobile-first portrait` play.

Mandatory rule:

- do not treat desktop browser validation as sufficient
- do not require desktop gameplay verification as a ship gate
- always run portrait-only checks
- treat portrait results as the release-blocking UI reference for gameplay screens

## Required Mobile Portrait Sizes

At minimum, verify these portrait viewport sizes:

| Label | Width | Height | Purpose |
| --- | --- | --- | --- |
| Small Android Portrait | `360` | `800` | compact HUD stress case |
| Common Android Portrait | `412` | `915` | realistic mid-size baseline |

## Required Tablet Portrait Sizes

Also verify these portrait tablet viewports:

| Label | Width | Height | Purpose |
| --- | --- | --- | --- |
| 9-inch Class Tablet Portrait | `768` | `1024` | compact tablet portrait |
| 11-inch Class Tablet Portrait | `834` | `1194` | large tablet portrait |

## Playwright Open Command

Recommended Windows-friendly command:

```powershell
npx --yes --package @playwright/cli playwright-cli open http://127.0.0.1:7357 --headed
```

Recommended artifact directory:

```powershell
output/playwright/<label>/
```

## Required Playwright Resize Steps

Before mobile smoke verification, resize the browser explicitly.

Example:

```powershell
npx --yes --package @playwright/cli playwright-cli resize 360 800
npx --yes --package @playwright/cli playwright-cli screenshot --filename output/playwright/<label>/phone-360x800.png
npx --yes --package @playwright/cli playwright-cli resize 412 915
npx --yes --package @playwright/cli playwright-cli screenshot --filename output/playwright/<label>/phone-412x915.png
npx --yes --package @playwright/cli playwright-cli resize 768 1024
npx --yes --package @playwright/cli playwright-cli screenshot --filename output/playwright/<label>/tablet-768x1024.png
npx --yes --package @playwright/cli playwright-cli resize 834 1194
npx --yes --package @playwright/cli playwright-cli screenshot --filename output/playwright/<label>/tablet-834x1194.png
```

Landscape guard check:

```powershell
npx --yes --package @playwright/cli playwright-cli resize 915 412
npx --yes --package @playwright/cli playwright-cli screenshot --filename output/playwright/<label>/landscape-915x412.png
```

## Required QA Harness For This Project

Because Flame scenes are not easily asserted through DOM refs alone, the project must add a small Flutter-side QA overlay for web validation.

Required overlay fields:

- current siege number
- current act number
- current assault cycle
- active fronts
- next fronts
- citadel HP
- gold
- selected buildable
- recovery timer
- game state: `prep`, `assault`, `recovery`, `clear`, `fail`

## Required QA Controls

Add debug-only controls so browser automation can validate game rules without pixel hunting only.

Recommended controls:

- start siege
- start next cycle
- skip recovery
- toggle pause
- restart siege
- spawn test wave by front
- simulate citadel damage

## Manual Smoke Checklist

For each milestone, verify:

- app launches on web
- title and home flow render
- entering a siege shows citadel, fronts, and build zones
- cycle transition shows recovery state
- next-front telegraph renders before the next cycle
- east-facing enemies mirror correctly
- north and south enemies use correct sprite set or explicit fallback
- citadel damage updates the HUD immediately
- result state persists after clear and fail
- portrait HUD does not cover the core battle area or front telegraphs
- build controls remain tappable at portrait widths
- recovery timer, gold, citadel HP, and active-front indicators remain readable at portrait widths
- landscape mode shows the portrait-only guard instead of attempting live gameplay

## Screenshot Review Rule

For Flame-heavy screens, screenshot review is required in addition to text assertions.

Minimum screenshot set:

- title or home flow
- prep phase
- mid-cycle with two fronts active
- recovery window
- final breach
- clear result
- fail result

For each milestone, capture those at:

- `360 x 800` portrait
- `412 x 915` portrait
- `768 x 1024` portrait
- `834 x 1194` portrait
