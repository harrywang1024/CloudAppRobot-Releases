CloudApp Robot PC EXE Release

1. Copy config.bot-template.json to config.pc.json
2. Edit config.pc.json
3. Keep WeChat logged in and open
4. Default startup entry is start_robot.cmd
5. start_pc_robot_exe.cmd is the direct runtime fallback for debugging
6. Keep agent_watchdog_enabled set to false unless explicitly testing watchdog behavior
7. start_ops_console.cmd is included for the ops-side desktop console
8. Keep WeChat open in foreground
9. To stop, run stop_pc_robot_exe.cmd

Detailed steps:
PC_ROBOT_PACKAGING_AND_DEPLOYMENT_SOP.md
