# CloudApp Robot Baseline 1.4.31

This document marks the current Windows robot baseline after the
runtime timestamp fix, the corrected updater-inclusive auto-update bundle,
and the helper-binary self-check was folded into the shipped executable.

## Baseline Summary

- Version: `1.4.31`
- Channel: `stable`
- Packaging target: Windows `onedir` EXE bundle
- Launch model:
  - `start_robot.cmd` starts the resident agent
  - the agent owns business startup, restart, and update follow-up
  - `start_pc_robot_exe.cmd` remains the direct runtime fallback for debugging
- Ops console companion baseline:
  - current manual install kit remains `1.4.30`
  - bot version is visible in the list
  - detail/version display is aligned with runtime version reporting
  - log diagnostics can switch a bot between normal and diagnostic log profiles

## What This Baseline Consolidates

1. Resident agent update orchestration is the default model.
2. Automatic update bundles now retain `CloudAppUpdater.exe`, so later upgrades
   do not dead-end on machines that already advanced once.
3. Robot status panel can warn when `CloudAppUpdater.exe` or
   `CloudAppAgent.exe` is missing locally.
4. Normal cloud runtime logging is reduced to the essential subset.
5. Diagnostic log mode is now remotely controllable from the ops side.
6. Runtime support bundles include local log-control state for investigation.

## Log Governance Direction In This Baseline

Normal mode:

- keep rich logs locally
- upload only essential runtime lines
- do not continuously mirror every archive to the cloud

Diagnostic mode:

- temporarily widen runtime uploads
- allow archive uploads for deeper investigation
- auto-expire back to normal mode after the configured duration

This is the first baseline where log behavior is intentionally separated into
`normal` and `diagnostic` profiles instead of treating cloud storage as a full
mirror of local logs.

## Recommended Operational Rules

- Use `start_robot.cmd` as the only normal startup entry on production machines.
- Keep each machine's own `config.pc.json` and `.robot_data`.
- Do not copy another robot's runtime data onto a new machine.
- Use ops-side diagnostic mode only when troubleshooting a live incident.
- Keep WeChat logged in and visible enough for GUI automation to reconnect.

## Verification Checklist

After deployment, verify:

1. `CloudAppAgent.exe` remains resident.
2. `CloudAppRobot.exe` is started by the agent and does not introduce flashing.
3. Backend `bot_version` / `runtime_bot_version` report `1.4.30`.
4. Ops console list view shows the bot version correctly.
5. Group-buy broadcast, order parsing, and status heartbeat all work normally.
6. Restarting the robot does not re-send already-issued stock alerts.

## Historical Note

`1.4.27` remains the earlier stabilization milestone for the resident-agent
startup fix, but `1.4.30` is now the active development and deployment baseline.
