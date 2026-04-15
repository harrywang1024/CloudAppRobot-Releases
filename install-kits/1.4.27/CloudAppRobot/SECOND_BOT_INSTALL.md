# Second Robot Installation Guide

This guide is for installing a second Windows robot on a new machine based on the `1.4.27` baseline.

## Files To Copy To The New Machine

Use the packaged release folder or zip produced from the current `onedir` build. The target machine should receive:

- `CloudAppRobot/` directory
- `CloudAppAgent.exe`
- `CloudAppUpdater.exe`
- `config.bot-template.json`
- `config.pc.newmachine.json`
- `start_robot.cmd`
- `stop_pc_robot_exe.cmd`
- `start_robot_status_panel.cmd`
- `stop_robot_status_panel.cmd`

## Target Machine Requirements

- Windows 10 or Windows 11
- PC WeChat installed
- Target WeChat account already logged in
- Network access to `https://40.233.102.106/api/v1`

## Recommended Install Path

Extract the package to a stable path such as:

```text
C:\CloudAppRobot\
```

The folder should finally look like:

```text
C:\CloudAppRobot\
  CloudAppRobot\
  CloudAppAgent.exe
  CloudAppUpdater.exe
  config.bot-template.json
  config.pc.newmachine.json
  start_robot.cmd
  stop_pc_robot_exe.cmd
```

## Config Preparation

1. Copy `config.pc.newmachine.json` to `config.pc.json`.
2. Edit `config.pc.json`.

Required fields to change:

- `username`
- `password`
- `bot_code`
- `openai_api_key`
- `leader_private_wechat`
- `monitored_conversations`
- `monitored_groups`

Recommended second-machine value:

- `bot_code`: `BOT-WECHAT-002`

Important:

- Do not reuse the first machine's `bot_code`.
- Do not copy `.robot_data` from another machine.
- Keep this machine's runtime paths local to this machine.

## First Startup

1. Make sure PC WeChat is open and logged in.
2. On the very first launch, run `start_robot.cmd` once as Administrator.
3. Wait for the robot to finish local key/session setup.
4. Later daily starts can use normal double-click startup.

## Normal Stop And Start

Start:

```text
start_robot.cmd
```

Stop:

```text
stop_pc_robot_exe.cmd
```

## What To Verify

1. `CloudAppRobot.exe` starts normally.
2. No periodic flashing appears.
3. WeChat stays logged in and usable.
4. Backend bot shows online heartbeat.
5. Backend `bot_version` and `runtime_bot_version` report `1.4.27`.
6. A test group-buy broadcast can be sent.
7. A test solitaire order can be parsed and reported.

## Runtime Data Location

In the packaged layout, runtime data is kept under:

```text
C:\CloudAppRobot\.robot_data\
```

Key folders:

```text
C:\CloudAppRobot\.robot_data\runtime\pc\
C:\CloudAppRobot\persistent_orders\
C:\CloudAppRobot\reports\
```

## Troubleshooting

If startup fails:

- check `config.pc.json` exists next to `start_robot.cmd`
- check WeChat is logged in and not minimized
- check `.robot_data\\runtime\\pc\\startup_bootstrap.log`
- check `.robot_data\\runtime\\pc\\group_bot_supervisor.log`

If the bot never appears online:

- verify API URL, username, and password
- verify the new `bot_code`
- verify the machine can reach the backend over HTTPS
