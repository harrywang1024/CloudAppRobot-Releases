# CloudApp Robot Baseline 1.4.29

This file locks the current robot + ops-side baseline after the resident-agent update flow, ops-console version visibility, stale/offline status fixes, and stock-reminder persistence fixes were verified in production.

## Baseline Scope

- Version: `1.4.29`
- Source of truth: [version.json](/d:/halfmiles/CloudApp/robot_client/version.json)
- Default robot startup entry: [start_robot.cmd](/d:/halfmiles/CloudApp/robot_client/start_robot.cmd)
- Direct robot fallback entry: [start_pc_robot_exe.cmd](/d:/halfmiles/CloudApp/robot_client/start_pc_robot_exe.cmd)
- Ops desktop entry: [start_ops_console.cmd](/d:/halfmiles/CloudApp/robot_client/start_ops_console.cmd)

## Stable In This Baseline

- Resident `CloudAppAgent.exe` orchestration model.
- Execution-only `CloudAppUpdater.exe`.
- Bundle-based remote upgrade flow verified end-to-end.
- Ops-side command history available for authorized leader-owned bots.
- Ops console absolute timestamps rendered in `America/Toronto`.
- Ops console bot list shows the robot version.
- Monitoring status normalizes `online`, `stale`, and `offline` consistently.
- Stock reminders use Chinese copy and persist dedupe state across normal restarts.

## Verified Flows

- Clean-machine manual deployment with the `onedir` EXE package.
- No periodic flashing on normal robot startup.
- Remote update drills:
  - `1.4.25 -> 1.4.26`
  - `1.4.26 -> 1.4.27`
- `1.4.28 -> 1.4.29`
- Ops-side update issuance directly from the desktop console.

## Packaging Rules

- Do not package machine-specific `config.pc.json` into delivery bundles.
- Use [config.bot-template.json](/d:/halfmiles/CloudApp/robot_client/config.bot-template.json) or [config.pc.newmachine.json](/d:/halfmiles/CloudApp/robot_client/config.pc.newmachine.json) as the starting template.
- Preserve each machine's own `config.pc.json`.
- Preserve each machine's own `.robot_data`, `persistent_orders`, and report-output directories.

## Ops-Side Baseline

- Main source: [ops_console.py](/d:/halfmiles/CloudApp/robot_client/ops_console.py)
- Launch script: [start_ops_console.cmd](/d:/halfmiles/CloudApp/robot_client/start_ops_console.cmd)
- Template config: [config.ops.template.json](/d:/halfmiles/CloudApp/robot_client/config.ops.template.json)

Expected ops behavior:

- `Commands` tab loads history for authorized ops users.
- `Issued At`, `Started At`, and `Finished At` show Toronto time.
- Robot versions are visible in the left bot list.
- Remote update can be issued from the ops desktop console.

## Future Development Rule

Use this baseline as the future development base. If a later issue appears, compare behavior against `1.4.29` first before layering new changes.
