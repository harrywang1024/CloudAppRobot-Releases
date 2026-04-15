# CloudAppRobot Install Kits

This branch stores browsable deployment files for manual robot installation.

Current available kits:

- `1.4.27/CloudAppRobot`
- `1.4.27/WeCloudappOpsConsole`

Recommended use:

1. Open `1.4.27/CloudAppRobot` for robot deployment or `1.4.27/WeCloudappOpsConsole` for the ops console.
2. Copy the whole directory to the target Windows machine.
3. For a new robot machine, use `config.pc.newmachine.json` as the starting config template.
4. Follow `SECOND_BOT_INSTALL.md` for robot setup.

Important:

- This branch is for manual deployment only.
- The auto-update system still reads `release-manifest.json` from the `main` branch.
