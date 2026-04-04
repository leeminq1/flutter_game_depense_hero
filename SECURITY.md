# Security

## Scope

This is a game project, so the biggest practical security risks are dependency hygiene, save-data trust, and asset provenance.

## Rules

- Prefer maintained packages and pin major version intent deliberately.
- Record source and license status for every external asset.
- Treat client save data as user-controlled input.
- Avoid storing secrets in the client bundle.
- If backend features are added later, move auth and economy authority off-device.

## LPC Asset Rules

- The LPC generator and spritesheets require attention to attribution and license compatibility.
- Store exported credits alongside the selected LPC asset set.
- Do not assume every selected LPC part is CC0; keep the license export as part of the asset record.
- If derivative art is made from LPC assets, preserve the obligations of the source license.

## AI Asset Hygiene

- Keep prompt logs for generated concepts.
- Record whether assets are final, derivative, or temporary placeholder work.
- Review output for unwanted logo, watermark, or trademark contamination before shipping.
