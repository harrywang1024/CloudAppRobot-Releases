# CloudAppRobot Install Kits

This branch stores browsable deployment files for manual robot installation.

Current available kits:

- `1.4.39/CloudAppRobot`
- `1.4.38/CloudAppRobot`

Recommended use:

1. Prefer `1.4.39/CloudAppRobot` for robot deployment, or fall back to `1.4.38/CloudAppRobot` only when you need the previous baseline.
2. Copy the whole directory to the target Windows machine.
3. For a new robot machine, use `config.pc.newmachine.json` as the starting config template.
4. Follow `SECOND_BOT_INSTALL.md` for robot setup.

Important:

- This branch is for manual deployment only.
- Only the latest two robot install kits are retained here.
- The auto-update system still reads `release-manifest.json` from the `main` branch.
