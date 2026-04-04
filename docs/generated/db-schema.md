# DB Schema

Proposed local-first persistence schema for an offline tower defense game.

Recommended backend for the first implementation: Isar.

## Collections

- `player_profile`
  - player_id
  - created_at
  - last_played_at
  - display_name
  - account_level
  - total_xp

- `wallet`
  - soft_currency
  - premium_currency
  - ad_reward_tokens

- `stage_progress`
  - stage_id
  - highest_clear_rating
  - unlocked
  - stars
  - first_clear_at
  - last_clear_at

- `tower_unlock`
  - tower_id
  - unlocked
  - level
  - shard_count

- `upgrade_node`
  - node_id
  - unlocked
  - level

- `session_history`
  - session_id
  - stage_id
  - started_at
  - ended_at
  - result
  - currency_earned
  - towers_used

- `settings`
  - language
  - sfx_volume
  - music_volume
  - vibration_enabled
  - ad_personalization_choice

- `reward_claim_log`
  - claim_id
  - source_type
  - source_ref
  - granted_at
  - payload_hash

Implemented prototype collections now also include:
- `reward_claim_record`
- `upgrade_node_record`

## Notes

- `reward_claim_log` exists to prevent duplicate grants after crash/restart boundaries.
- Session combat state should not be continuously persisted unless we later add resume support.
- If cloud sync is added later, treat this schema as the client cache and sync source, not the authority.
