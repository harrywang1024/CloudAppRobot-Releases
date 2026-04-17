# CloudApp Robot Baseline 1.4.38

This document marks the Windows robot baseline after fixing the
post-update command replay loop that could keep a freshly updated bot offline.

## Baseline Summary

- Version: `1.4.38`
- Channel: `stable`
- Packaging target: Windows `onedir` EXE bundle
- Launch model:
  - `start_robot.cmd` starts the resident agent
  - the agent remains the default owner for update orchestration
  - supervisor fallback only intervenes when the agent is stale

## What This Baseline Consolidates

1. The agent now removes a locally queued `update_to_version` command before
   handing control to `CloudAppUpdater.exe`, so the same command does not remain
   in `remote_commands.json` after the updater restart.
2. If the updater or restart sequence fails after that handoff, the agent
   re-queues the command locally so the machine does not silently drop the
   update request.
3. The supervisor now checks for a fresh pending update-completion marker before
   taking over a queued remote update command. If the agent has already handed
   the update off and is waiting for restart confirmation, the supervisor skips
   fallback instead of repeatedly stopping the runtime.
4. This removes the dead-loop where a newly updated machine could start the
   runtime, immediately see the same queued update command again, kill the
   runtime, and eventually go offline from heartbeat timeout.

## Recommended Operational Rules

- If a machine reports `agent is stale/unavailable`, verify whether an update is
  already in progress before manually restarting services.
- When investigating a failed update, check the local pending update marker and
  remote command queue together instead of only checking the backend command
  history.
- Upgrade any machine that previously entered repeated update fallback loops to
  `1.4.38`.

## Verification Checklist

After deployment, verify:

1. The backend reports `bot_version` / `runtime_bot_version` as `1.4.38`.
2. A fresh update command reaches `acknowledged`, `downloading`, `installing`,
   and `restarting` without staying stuck at `dispatched`.
3. After updater handoff, the local remote command queue no longer keeps the
   same `command_id`.
4. The supervisor does not repeatedly log `Queued remote update command(s)
   detected while agent is stale/unavailable` for the same command after the
   restart begins.
5. The runtime remains up after restart instead of being killed again by a
   replayed update command.

## Historical Note

`1.4.37` refreshed the packaged PC robot build. `1.4.38` hardens the update
handoff so a successful package install does not get undone by a stale local
remote command replay loop.
