# PC Robot Packaging And Deployment SOP

## Scope

This SOP is for the current Windows PC WeChat robot mainline that has already been stabilized in this repo:

- PC WeChat DB reading
- PC WeChat OCR sending
- Supervisor -> runtime wrapper -> sender worker
- Local order persistence and finalize sync
- Weekly leader report generation and delivery

The target delivery direction is now:

1. `onedir` EXE release
2. source release bundle as fallback
3. `onefile` EXE only for experiments

## Current Recommendation

Prefer an **onedir EXE package**.

Reason:

- target machines do not need Python just to run the robot
- the frozen entry has been realigned to the current stable roles
- it avoids the `onefile` DLL extraction issue we hit on this machine

## Target Machine Requirements

### OS

- Windows 10 or Windows 11

### Software

- PC WeChat installed and logged in
- Python 3.11 x64 only if you want to rebuild the EXE on that machine

### WeChat state

- the target WeChat account must already be logged in
- WeChat window must remain available in foreground
- do not minimize WeChat while the robot is working
- on the first EXE launch on a new machine, run the robot once as Administrator so it can extract WeChat DB keys
- after keys are extracted successfully, normal background launches can usually run without Administrator

### Network

- must be able to access backend API
- if weekly report is used, backend report APIs and migrations must already be deployed

## Build The EXE Release

On the build machine:

```powershell
cd C:\CloudApp\robot_client
python -m pip install pyinstaller
python build_exe.py --mode onedir
powershell -ExecutionPolicy Bypass -File scripts/windows/package_pc_robot_exe_release.ps1
```

Output:

```text
robot_client\release\CloudAppRobot-pc-exe-YYYYMMDD_HHMMSS\
robot_client\release\CloudAppRobot-pc-exe-YYYYMMDD_HHMMSS.zip
```

## Install On A Clean PC

1. Copy the EXE release zip to the clean PC.
2. Extract it to a stable path, for example:

```text
C:\CloudAppRobot\
└─ CloudAppRobot\
   ├─ CloudAppRobot.exe
   ├─ config.bot-template.json
   ├─ start_pc_robot_exe.cmd
   ├─ stop_pc_robot_exe.cmd
   ├─ PC_ROBOT_PACKAGING_AND_DEPLOYMENT_SOP.md
   └─ ...
```

3. Copy `config.bot-template.json` to `config.pc.json`.
4. Edit `config.pc.json`.

Minimum required fields:

- `api_base_url`
- `username`
- `password`
- `bot_code`
- `openai_api_key`
- `leader_private_wechat`
- `monitored_groups`

Strongly recommended machine-local fields:

- `local_order_backup_dir`
- `leader_report_output_dir`

Recommended example on target machine:

```json
{
  "api_base_url": "https://YOUR_SERVER/api/v1",
  "username": "YOUR_USERNAME",
  "password": "YOUR_PASSWORD",
  "bot_code": "BOT-WECHAT-002",
  "openai_api_key": "sk-REPLACE_WITH_REAL_KEY",
  "leader_private_wechat": "LeaderName",
  "enable_order_broadcast_send": true,
  "send_backend": "pc_wechat_ocr",
  "pc_wechat_send_config": "pc_wechat_send_config.template.json",
  "enable_stock_monitor": true,
  "enable_notice_queue": true,
  "cold_start_baseline": true,
  "windows_db_limit": 800,
  "windows_db_max_blocks_per_group": 30,
  "runtime_recent_extra_blocks": 30,
  "local_order_backup_dir": "C:/CloudAppRobot/persistent_orders/pc",
  "leader_report_output_dir": "C:/CloudAppRobot/reports",
  "leader_report_timezone": "America/Toronto",
  "leader_report_weekly_schedule": [
    {
      "weekday": "Friday",
      "time": "18:00"
    }
  ],
  "monitored_groups": [
    "Group A",
    "Group B"
  ],
  "poll_interval": 2.0,
  "sync_interval": 30,
  "ocr_analyze_self_messages": true
}
```

## Start On The Clean PC

Recommended:

```text
start_pc_robot_exe.cmd
```

This starts the robot in background.

Important on a clean PC:

1. keep PC WeChat logged in and open
2. on the very first launch, run `start_pc_robot_exe.cmd` as Administrator once
3. wait until runtime logs no longer show key extraction failure
4. later daily starts can go back to normal background mode

Equivalent direct command:

```powershell
CloudAppRobot.exe --pc-role supervisor --instance-id pc --bot-config config.pc.json
```

## Stop On The Clean PC

Recommended:

```text
stop_pc_robot_exe.cmd
```

The stop script reads PID files from the runtime directory and stops:

- supervisor
- runtime
- sender

Fallback:

- use Task Manager if needed

## Runtime Data Location

In EXE mode, runtime state is stored outside the bundle so it survives EXE replacement.

Default data root:

```text
%APPDATA%\CloudAppRobot\
```

Important paths:

```text
%APPDATA%\CloudAppRobot\runtime\pc\
%APPDATA%\CloudAppRobot\group_bot.log
```

If `CLOUDAPP_ROBOT_DATA_DIR` is set, that path becomes the runtime data root.

## Background Run Model

The intended model is:

- robot runs in background
- WeChat remains the only foreground application
- no permanent console window is required

So on the target PC:

- robot process: background
- WeChat window: foreground / visible

## Auto Start At Login

If you still deploy from source mode, use:

- [install_pc_robot_autostart.ps1](/d:/halfmiles/CloudApp/robot_client/scripts/windows/install_pc_robot_autostart.ps1)
- [uninstall_pc_robot_autostart.ps1](/d:/halfmiles/CloudApp/robot_client/scripts/windows/uninstall_pc_robot_autostart.ps1)

For EXE mode, the same scheduled-task idea can be reused later with `start_pc_robot_exe.cmd`.

## Verification Checklist

After deployment:

1. Start the robot with `start_pc_robot_exe.cmd`
2. Confirm WeChat remains open and usable
3. Confirm runtime data appears under `%APPDATA%\CloudAppRobot\runtime\pc\`
4. Confirm logs are updating:
   - `group_bot.log`
   - `runtime\pc\group_bot_supervisor.log`
   - `runtime\pc\group_bot_stdout.log`
   - `runtime\pc\pc_sender_worker.log`
5. On first launch, confirm key extraction succeeded and `third_party\wechat-decrypt\all_keys.json` exists under the data root
6. Start one group buy from backend
7. Confirm broadcast is sent to the right monitored group
8. Post a solitaire order in group
9. Confirm local order JSON appears under runtime or backup directories
10. End the group buy
11. Confirm finalize reaches backend
12. Trigger weekly report once if needed

## Manual Weekly Report Trigger

If you still have source tools available:

Dry run:

```powershell
python robot_client\trigger_leader_report_once.py --config robot_client\config.pc.json
```

Generate and send:

```powershell
python robot_client\trigger_leader_report_once.py --config robot_client\config.pc.json --send
```

If you are using pure EXE deployment, keep this as a builder-side or support-machine tool until a dedicated EXE wrapper is added.

## EXE Status

### onedir

`onedir` is now the practical EXE path.

What is already validated:

- EXE build succeeds
- sender role can boot in frozen mode
- runtime chain now enters business initialization in frozen mode
- frozen runtime data can be redirected away from `%APPDATA%`

### onefile

`onefile` is still experimental.

Known issue on this machine:

- runtime DLL extraction friction (`MSVCP140_1.dll`)

So do not use `onefile` for production rollout yet.

## Troubleshooting

### Start script says `CloudAppRobot.exe not found`

Make sure the script is inside the extracted EXE folder, next to `CloudAppRobot.exe`.

### Start script says `config.pc.json not found`

Copy `config.bot-template.json` to `config.pc.json` first.

### Robot starts but does not work

Check:

- WeChat is logged in
- WeChat is visible and not minimized
- backend login in config is correct
- `openai_api_key` is present in `config.pc.json`
- `%APPDATA%\CloudAppRobot\group_bot.log`
- `%APPDATA%\CloudAppRobot\runtime\pc\group_bot_stdout.log`

### Orders are not finalizing

Check:

- local order JSON still exists
- runtime is still running when group buys end
- backend API points to the intended environment

### Weekly report generates but is not sent

Check:

- `leader_private_wechat`
- sender log
- generated `.xlsx` exists under report output dir

## Final Recommendation

For now:

- package and deploy the **onedir EXE release**
- use `start_pc_robot_exe.cmd` and `stop_pc_robot_exe.cmd` on target machines
- keep DB keys, decrypt cache, and machine-local runtime data on the target machine
- treat `onefile` as experimental only
