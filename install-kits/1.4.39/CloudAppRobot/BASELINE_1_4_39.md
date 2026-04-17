# CloudApp Robot Baseline 1.4.39

This document marks the Windows robot baseline after consolidating the recent
solitaire broadcast wording adjustments together with another hardening pass on
local update-command cleanup.

## Baseline Summary

- Version: `1.4.39`
- Channel: `stable`
- Packaging target: Windows `onedir` EXE bundle
- Launch model:
  - `start_robot.cmd` starts the resident agent
  - the agent remains the default owner for update orchestration
  - supervisor/runtime fallback only take over when the agent is stale

## What This Baseline Consolidates

1. The current solitaire / order-broadcast wording logic is included in the
   packaged PC robot build so the release matches the already tested broadcast
   text behavior.
2. The agent now prunes stale locally queued `update_to_version` commands after
   startup and after pending update completion is finalized, preventing old
   commands from replaying on an already upgraded machine.
3. The supervisor and runtime wrapper now prune or skip stale local update
   commands whose `target_version` is already less than or equal to the current
   installed version.
4. Stale `pending_remote_update.json` completion markers can now be cleared
   automatically once the target version is already installed and the matching
   local queue entry no longer exists.
5. This reduces the risk of repeated fallback update processing, flashing `cmd`
   windows, and bots going offline because an old local queue item keeps being
   replayed after a newer version is already running.

## Recommended Operational Rules

- Keep using the resident agent as the normal update owner.
- If a machine looks stuck on an old update, inspect local files in this order:
  `remote_commands.json`, then `pending_remote_update.json`.
- If the machine is already on the target version, stale local queue entries
  should now self-heal instead of requiring repeated manual cleanup.
- Continue the current operational requirement that WeChat stays docked to the
  right side of the screen and that operators manually keep the send area large
  enough for safe clicking.

## Verification Checklist

After deployment, verify:

1. The backend reports `bot_version` / `runtime_bot_version` as `1.4.39`.
2. Order-broadcast text still follows the updated solitaire wording behavior on
   a live group-buy run.
3. A machine with an already completed update does not keep replaying the same
   local `update_to_version` command after restart.
4. `remote_commands.json` does not retain stale update rows whose target
   version is already installed.
5. The robot stays online after restart instead of falling back into another
   replay loop.

## Historical Note

`1.4.38` fixed the post-update replay loop during updater handoff.
`1.4.39` extends that hardening by pruning stale local queue state even when an
older update command survives on disk after a later successful upgrade.
