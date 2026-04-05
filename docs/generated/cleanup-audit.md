# Cleanup Audit

## Purpose

Track which files were removed because they were not part of runtime gameplay or were not referenced by the current asset catalogs.

## Current Cleanup Pass

- removed unused dependency entries for `cupertino_icons` and `google_mobile_ads`
- rebuilt `.gitignore` so temporary sprite experiments and LPC debug dumps stop reappearing in the worktree
- deleted root-level `tmp*.png` experiment files
- deleted root-level `output_lpc_*.js` LPC reverse-engineering dumps
- deleted transient `output/*.log`
- deleted transient `output/lpc_check*` experiment folders
- deleted transient `output/playwright/*` scratch files
- removed unused bundled audio files not referenced by `AudioCatalog`

## Intentionally Kept

- `assets/sprites/**`
  - runtime loading is dynamic and these are real game assets
- `output/barracks_defender_preview.png`
  - still useful as a roster reference sheet
- `output/crest_stage_scene_preview.png`
  - referenced by map-production docs
- `tools/lpc-export/node_modules`
  - not part of the shipped app, but retained to avoid slowing future LPC export passes

## Rule Going Forward

- if a file is not referenced by runtime code and is only a local experiment artifact, remove it or ignore it immediately
- if a file helps document art or map review and is referenced from docs, keep it until the docs move away from it
