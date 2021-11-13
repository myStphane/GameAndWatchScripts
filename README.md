# GameAndWatchScripts
my Game &amp; Watch Script (Backup &amp; retro-go)

Notes:
- UbuntuInstall.txt is a scrappy text file with all my commands ran for an Ubuntu install under an Oracle VM VirtualBox env. for G&W Backup & retro-go
- On script run, for each option/action, a user key-press is requested, to avoid any miss run actions => user can press Ctrl+C to abort it.

Debugger:
- I use a ST-Link V2 (Clone) debugger



## 0_menu.sh
Aim: (my) menu / Ubuntu for the G&W Backup tools
- Source: https://github.com/ghidraninja/game-and-watch-backup/

Process:
- Install the 0_menu.sh in root menu of your game-and-watch-backup folder

Additional used documentation:
- a really (really) usefull video: https://www.youtube.com/watch?v=-MzmoEFs0bQ
- "A Novice Hacking A Game & Watch": https://docs.google.com/document/d/1-x6tibLxtOPf6ZbQL0ZM48XGe1-LLEfl8HpBg8gBu_M/edi
- (my) Game & Watch Backup, ie, my Google Doc “step-by-step”: https://docs.google.com/document/d/1Eh8K309A5QMHd1iv1lm_Zd7EstZ42Sgaa8ed8rIN72I/
 

## retro-go.sh & UbuntuInstall.txt
Aim: (my) retro-go menu / Ubuntu

- Source : https://github.com/kbeckmann/game-and-watch-retro-go
- Discord: https://discord.com/channels/781528730304249886/784362150793707530

Usage:
- Install the retro-go.sh (& the optional UbuntuInstall.txt file) in root menu of your retro-go folder
- Tune befor start script the export variables in script

Note:
- the "3 * Patch interface_stlink.cfg" option is optional, but helps me to copy in place _before all_, my dedicated .cfg file to lower my ST-Link adapter speed

Missing:
- git "install" section (even if there is a git update one, I guess some folder(s) pre-creation and "git init" actions may be "enougth" => need to improve my script).
