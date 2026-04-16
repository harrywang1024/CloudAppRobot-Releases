# CloudApp Robot Baseline 1.4.36

This document marks the Windows robot baseline after fixing the
PC WeChat send-area geometry model used by order broadcast focus recovery.

## Baseline Summary

- Version: `1.4.36`
- Channel: `stable`
- Packaging target: Windows `onedir` EXE bundle
- Launch model:
  - `start_robot.cmd` starts the resident agent
  - the agent remains the default owner for startup, restart, and update follow-up
  - `start_pc_robot_exe.cmd` remains the direct runtime fallback for debugging

## What This Baseline Consolidates

1. The WeChat window still standardizes to the top-right of the screen with
   taskbar-aware height reservation.
2. Auto-calibration no longer saves a tiny bottom-strip `input_rect` around the
   input point. It now saves the full composer region used for send-area focus.
3. The calibrated input point is biased to the right-middle of the composer,
   which is the safest click zone for clipboard paste before Enter send.
4. Runtime focus recovery no longer blindly trusts stale narrow `input_rect`
   data from older machines. If the saved region is too narrow, too short, or
   anchored too low, the sender falls back to a window-ratio-derived composer
   region.
5. This removes the root cause behind repeated `pc_focus_failed` loops where the
   mouse kept hovering inside the send area without ever reaching the paste step.

## Recommended Operational Rules

- Keep the WeChat window docked against the right edge of the screen.
- Let the robot regenerate GUI calibration after a major layout change.
- If an older robot keeps looping in the send area, upgrade it to `1.4.36`
  before spending time manually adjusting click coordinates.

## Verification Checklist

After deployment, verify:

1. `CloudAppAgent.exe` remains resident.
2. Backend `bot_version` / `runtime_bot_version` report `1.4.36`.
3. Order broadcast no longer loops on `pc_focus_failed` while hovering in the
   send area.
4. The robot clicks inside the right-middle composer area, pastes content, and
   sends with Enter.
5. Older machines with stale GUI calibration recover without requiring manual
   deletion of the existing config in the common case.

## Historical Note

`1.4.35` remains the prior release baseline focused on right-edge window
anchoring and stale-agent update recovery. `1.4.36` adds the send-area geometry
fix that makes the right-edge strategy reliably usable during order broadcast.
