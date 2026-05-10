# Google Play Submission Assets

Updated on 2026-05-10 for `PIXEL GUARD:WAVE`.

## App Identity

```text
App name: PIXEL GUARD:WAVE
Package name: com.min21.pixelguardwave
Default language: Korean - ko-KR
Track: Closed testing
```

## Copy/Paste Docs

Google Play Console input docs live in:

```text
docs/generated/google-play/docs/
```

Start with:

```text
docs/generated/google-play/docs/00-google-play-entry-index.md
```

## Polished Phone Screenshots

Generated screenshots live in:

```text
docs/generated/google-play/screenshots/
```

Files:

- `phone-screenshot-01-title.png`
- `phone-screenshot-02-camp.png`
- `phone-screenshot-03-hero.png`
- `phone-screenshot-04-briefing.png`
- `phone-screenshot-05-battle.png`

Each output is `1080x2640` and preserves the raw screenshot dimensions.

To regenerate:

```powershell
python docs\generated\google-play\source\render_store_screenshots.py
```

## Privacy Policy Site

GitHub Pages source files:

- `docs/privacy-policy/index.html`
- `docs/privacy-policy/privacy-policy.md`
- `docs/.nojekyll`

Play Console URL after GitHub Pages is enabled from branch `main`, folder `/docs`:

```text
https://leeminq1.github.io/flutter_game_depense_hero/privacy-policy/
```

## Store Notes

- Feature graphic requirement: 1024x500 JPEG or 24-bit PNG with no alpha.
- Phone screenshots must be JPEG or 24-bit PNG with no alpha.
- Current phone screenshots are 1080x2640 PNG without alpha.
