# GameAndWatch
my Game &amp; Watch Script (Backup &amp; retro-go) & other "help" files

Notes:
- On any script run, for each option/action, a user key-press is requested, to avoid any miss run actions => user can press Ctrl+C to abort it.
- Debugger: I use a *ST-Link V2* (Clone) debugger, however, the debugger is always asked to user on script start
- Game & Watch: I use (actually) a *G&W Super Mario Bros.* version (not the new Zelda one), however, the G&W model type is asked to user on script start


## Main sources for Backup(& unlock), retro-go + Ubuntu guides
- Backup: https://github.com/ghidraninja/game-and-watch-backup (the README)
- retro-go: https://github.com/kbeckmann/game-and-watch-retro-go (the README)
  - LCD Game shrinker: https://gist.github.com/DNA64/16fed499d6bd4664b78b4c0a9638e4ef
  - For covers "option": https://discord.com/channels/781528730304249886/783282561001717771/915175310377504799
- (video) https://www.youtube.com/watch?v=-MzmoEFs0bQ (mainly from 2:17 to 4:25)
- (Discord channed) pinned guide: https://docs.google.com/document/d/1-x6tibLxtOPf6ZbQL0ZM48XGe1-LLEfl8HpBg8gBu_M/edit
- (my) Backup & unlock Google Doc: https://docs.google.com/document/d/1Eh8K309A5QMHd1iv1lm_Zd7EstZ42Sgaa8ed8rIN72I/edit#
- (my) Ubuntu (install) guide: check current _UbuntuInstall.txt_ file


## LinuxCommandsForDummies.txt 
As named: here some linux (Ubuntu) commands for dummies, quickly explained + ex.


## UbuntuInstall.txt
- Is a text file with all my commands ran for an Ubuntu install under an Oracle VM VirtualBox env. for G&W Backup & retro-go
- This was a step-by-step actions & commands I followed for zero toe have a fully "G&W" installed environment (most are extracts from the G&W Backp & retro-go "README" parts & extracts from Discrod helps)



## 0_menu.sh
Aim: (my) menu / Ubuntu for the G&W Backup tools
- Source: https://github.com/ghidraninja/game-and-watch-backup/

Mandatory:
- Having flashed (& backup/unlocked) your device


Process:
- Copy the *0_menu.sh* in root menu of your game-and-watch-backup folder
- Make it executable (`chmod +x 0_menu.sh`)

Additional used documentation:
- a really (really) usefull video: https://www.youtube.com/watch?v=-MzmoEFs0bQ
- "A Novice Hacking A Game & Watch": https://docs.google.com/document/d/1-x6tibLxtOPf6ZbQL0ZM48XGe1-LLEfl8HpBg8gBu_M/edi
- (my) Game & Watch Backup, ie, my Google Doc “step-by-step”: https://docs.google.com/document/d/1Eh8K309A5QMHd1iv1lm_Zd7EstZ42Sgaa8ed8rIN72I/
 

## retro-go.sh (& UbuntuInstall.txt)
Aim: (my) retro-go menu / Ubuntu

- Source : https://github.com/kbeckmann/game-and-watch-retro-go
- Discord: https://discord.com/channels/781528730304249886/784362150793707530

Usage:
- Copy the *retro-go.sh* (& the optional UbuntuInstall.txt file) in root menu of your retro-go folder
- Make it executable (`chmod +x retro-go.sh`)
- Tune before start script the export variables in script

Note:
- the "3 * Patch interface_stlink.cfg" option is optional, but helps me to copy in place _before all_, my dedicated .cfg file to lower my ST-Link adapter speed

Missing:
- git "install" section (even if there is a git update one, I guess some folder(s) pre-creation and "git init" actions may be "enougth" => need to improve my script).
- nevertheless, one can follow the _README_ docs. from both G&W git repositories & my current _UbuntuInstall.txt_ file

## Warning note
Use all as it is, at your own risk...
