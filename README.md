# CloudAppRobot Install Kits

This branch is for manual deployment only.

- `main` remains the source of truth for robot auto-update metadata.
- `install-kits` contains the current browsable Windows install kits.

## Current Baseline

- Robot kit: `install-kits/1.4.31/CloudAppRobot`
- Ops console kit: `install-kits/1.4.30/WeCloudappOpsConsole`

## Direct Download

Download the whole `install-kits` branch as a zip:

`https://github.com/harrywang1024/CloudAppRobot-Releases/archive/refs/heads/install-kits.zip`

After extracting, use:

- `install-kits/1.4.31/CloudAppRobot`
- `install-kits/1.4.30/WeCloudappOpsConsole`

## Notes

- Older install kits have been removed from this branch to avoid downloading the wrong baseline.
- For a new robot machine, start from `config.pc.newmachine.json`.
- Follow `SECOND_BOT_INSTALL.md` inside the robot kit for setup.
