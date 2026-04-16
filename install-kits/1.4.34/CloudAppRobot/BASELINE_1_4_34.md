# CloudApp Robot Baseline 1.4.34

This document marks the current Windows robot baseline after the
PC WeChat standard-window policy was tightened to scale from the
machine's screen resolution instead of a narrow fixed-width cap.

## Baseline Summary

- Version: `1.4.34`
- Channel: `stable`
- Packaging target: Windows `onedir` EXE bundle
- Launch model:
  - `start_robot.cmd` starts the resident agent
  - the agent owns business startup, restart, and update follow-up
  - `start_pc_robot_exe.cmd` remains the direct runtime fallback for debugging
- Ops console companion baseline:
  - current manual install kit remains versioned independently
  - bot version is visible in the list
  - detail/version display is aligned with runtime version reporting

## What This Baseline Consolidates

1. Resident agent update orchestration remains the default model.
2. Automatic update bundles retain `CloudAppUpdater.exe`, so later upgrades
   do not dead-end on machines that already advanced once.
3. The PC WeChat standard window width is now computed from screen width,
   with the current rule set to `50%` of the screen.
4. Standard window height still reserves the bottom taskbar area instead of
   forcing a full-screen-height client area.
5. High-resolution machines are no longer forced back into the old narrow
   `800-1000px` width band during reconnect.
6. Release publishing continues to sync the shipped bundle's `version.json`
   with the published release metadata.

## Recommended Operational Rules

- Use `start_robot.cmd` as the only normal startup entry on production machines.
- Keep each machine's own `config.pc.json` and `.robot_data`.
- Do not copy another robot's runtime data onto a new machine.
- Keep WeChat logged in and visible enough for GUI automation to reconnect.
- If a machine has a very unusual display layout, verify the standard window
  shape once after the upgrade.

## Verification Checklist

After deployment, verify:

1. `CloudAppAgent.exe` remains resident.
2. `CloudAppRobot.exe` is started by the agent and does not introduce flashing.
3. Backend `bot_version` / `runtime_bot_version` report `1.4.34`.
4. On a `2736x1824` screen, the WeChat standard window width lands near
   `1368px`, while height still reserves the bottom taskbar.
5. Group-buy broadcast, order parsing, and status heartbeat all work normally.

## Historical Note

`1.4.33` remains the prior release baseline, while `1.4.34` becomes the
preferred robot deployment baseline for high-DPI window sizing.
