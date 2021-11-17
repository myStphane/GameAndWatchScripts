#!/bin/bash
# Source : https://github.com/kbeckmann/game-and-watch-retro-go
# Discord: https://discord.com/channels/781528730304249886/784362150793707530
# -------------------------------------------------
# Script: 20211117
# Owner : myStph
# -------------------------------------------------



# =================================================
# GLOBAL VARIABLES
# =================================================
## WARNING: if change one parameters => perform a 'make clean'
## Note: further (below) usage for variables is:
### $ time make -j$nproc COMPRESS=$compress GNW_TARGET=$gnwtarget EXTFLASH_SIZE_MB=$extflashMB CHECK_TOOLS=$checktools ENABLE_SCREENSHOT=$screenshot [flash]
## Tips: search below in file for "time make"

# Number of CPU for compilation
export nproc=4

# Source: https://discord.com/channels/781528730304249886/784362150793707530/837755406129430588
# export compress=[lz4|zopfli|lzma] / Deprecated: export compress=1
# export compress=lz4
export compress=lzma

# Source: https://discord.com/channels/781528730304249886/783282561001717771/841015223228825610
# Check for installed tools: gcc version 10 / objcopy elf32-littlearm / objdump arm7e-m
# Can be ignored by setting =0
export checktools=1

# Source: https://github.com/kbeckmann/game-and-watch-retro-go/commit/ee3cb5e9b5f93ef0a7bf664d9b70b2f1f06675a0
# Source: https://discord.com/channels/781528730304249886/784362150793707530/904170533002805339
# Can be ignored by setting =0
export screenshot=0

# GNW_TARGET=[mario|zelda]
## export gnwtarget=mario

# Deprecated: (if use the git handling the GNW_TARGET variable)
## Having soldered a bigger chip or using Zelda G&W?
## Default is: for G&W Mario = 1 (for 1Mb) / for G&W Zelda = 4 (for 4Mb)
# export extflashMB=1

# -------------------------------------------------
# Leave ADAPTER variable *empty* for query on script start.
# One may force it with: [stlink|jlink|rpi]
# export ADAPTER=stlink
export ADAPTER=

# -------------------------------------------------
# Mandatory Folders...
export OPENOCD=/opt/openocd-git/bin/openocd
export GCC_PATH=/home/ubuntu/game-and-watch/gcc-arm-none-eabi-10-2020-q4-major/bin/
export PATH=$GCC_PATH:$PATH

# -------------------------------------------------
# git repository URLs
export URL_flashloader=github.com/ghidraninja/game-and-watch-flashloader
export URL_retrogo=github.com/kbeckmann/game-and-watch-retro-go

# -------------------------------------------------
# Extra folders
export Roms_Folder=/mnt/share/roms
export Scr_Folder=/mnt/share/scr
export BKP_Folder=/mnt/share/bkp
export BKP_NbToList=5

# myPatch(s) & tools
mkdir -p ../game-and-watch-mytools 2>/dev/null





# =================================================
# FUNCTIONS
# =================================================
function _mySeparator() {
	echo
	echo "# --------------------------------------------------------------------------------------------------"
}
# -------------------------------------------------
function _myPause() {
	# read -p "Press [ENTER] to continue"
	read -p "Press [ENTER] to continue, Ctrl+C to abort "
}

# =================================================
function _myRetroGoKeys() {
	echo "# G&W Screen"
	echo "## GAME  : About & Debug"
	echo "## TIME  : Time  & Date"
	echo "## PAUSE : Brightness & Volume"
	echo "## B     : Rom properties"
	echo "## A     : Rom start (Resume/New game)"
	echo
	echo "# In game Screen"
	echo "## GAME  : START/Option in game"
	echo "## TIME  : SELECT/Pause game"
	echo "## PAUSE : Emulator menu (Save/Reload/Options.../Quit)"
	echo
	echo "## Note  : Press G&W Power button   : the state of the game will be saved before turning off."
	echo "##         Use the menu \"Power off\" : it will turn off without saving state."
	echo
	echo "## Macros"
	cat README.md|grep "^|"|grep -e "PAUSE/SET"|sed "s/^|/###/g"|sed "s/|$//g"|sed "s/|/:/g"
	echo
}

# =================================================
function _mySanityCheckListVar() {
	echo "# nproc        = $nproc	(number of CPU for compilation)"
	echo "# compress     = $compress	(use .lz4 or .zopfli compress for roms?)"
	echo "# checktools   = $checktools	(check installed tools?)"
	echo "# screenshot   = $screenshot	(allow to take a screenshot?)"
	echo "# gnwtarget    = $gnwtarget	(mario|zelda?)"
	# echo "# extflashMB   = $extflashMB	(external Flash size, in MB / default G&W Mario=1, Zelda=4)"
	echo "# ADAPTER      = $ADAPTER"
}
# -------------------------------------------------
function _mySanityCheckListFolders() {
	echo "# OPENOCD      = $OPENOCD"
	echo "# GCC_PATH     = $GCC_PATH"
	echo "# PATH         = $PATH"
	echo "# Roms_Folder  = $Roms_Folder/"
	echo "# Scr_Folder   = $Scr_Folder/"
	echo "# BKP_Folder   = $BKP_Folder/<YYMMDD_hhmiss>.<sav|tgz>"
	echo "# BKP_NbToList = ${BKP_NbToList}"
}
# -------------------------------------------------
function _mySanityCheckGit() {
	git_github=`git ls-remote git://${URL_flashloader}|head -1|awk '{print $1}'`
	git_github=`git ls-remote git://${URL_flashloader}|head -1|awk '{print $1}'`
	git_local=`git --git-dir ../game-and-watch-flashloader/.git log|sed "s/commit //g"|head -1`
	if [ "$git_github" == "$git_local" ] ; then git_cmp=" (OK)" ; else git_cmp=" (KO: local is older)"; fi
	echo "# Source: https://${URL_flashloader}"
	echo "	github git log game-and-watch-flashloader: $git_github"
	echo "	local  git log game-and-watch-flashloader: $git_local ${git_cmp}"
	echo "	`git --git-dir ../game-and-watch-flashloader/.git log|sed "s/commit //g"|head -3|tail -1`"
	echo
	git_github=`git ls-remote git://${URL_retrogo}|head -1|awk '{print $1}'`
	git_local=`git log|sed "s/commit //g"|head -1`
	if [ "$git_github" == "$git_local" ] ; then git_cmp=" (OK)" ; else git_cmp=" (KO: local is older)"; fi
	echo "# Source: https://${URL_retrogo}"
	echo "	github git log game-and-watch-retro-go:    $git_github"
	echo "	local  git log game-and-watch-retro-go:    $git_local ${git_cmp}"
	echo "	`git log|sed "s/commit //g"|head -3|tail -1`"
}	
function _mySanityCheckDebugger() {
	export RetVal=`ls -la /dev/|grep ${debugger}`
	if [ "-#$RetVal#-" == "-##-" ] ; then
		echo "                                                                                             (KO: incorrectly detected)"
	else
		echo "        $RetVal (OK)"
	fi
}
function _mySanityCheckOpenocd() {
	echo "# List 'openocd' process (mandatory: empty)"
	# ps -e | grep openocd|sed "s/^/        /"
	export RetVal=`ps -e | grep openocd`
	if [ "-#$RetVal#-" == "-##-" ] ; then
		echo "                                                                                             (OK)"
	else
		echo "        $RetVal                                                    (KO: background running)"
		# echo "        $RetVal                                                                (KO)"
		# export openocdPID=`ps -ef|grep openocd|grep -v grep|grep "init; halt"|awk '{print $2}'`
		# if [ "-#${openocdPID}#-" == "-##-" ] ; then
		# echo "                                                                                       (KO)" ; else echo "        $RetVal (OK)"; fi
	fi
}
function _mySanityCheck() {
	echo "1.0) Script vers."
	head retro-go.sh|grep Script

	echo
	echo "1.1) Get cpuinfo"
	echo "# get nproc from /proc/cpuinfo"
	grep -c ^processor /proc/cpuinfo

	echo
	echo "1.2) Check env. variables content"
	_mySanityCheckListVar

	echo
	echo "1.3) Check env. folders"
	_mySanityCheckListFolders

	echo
	echo "1.4) OpenOCD & GCC --vers"
	echo "# $OPENOCD --vers"
	echo "## NOTE: works (on 20210505) with: \"Open On-Chip Debugger 0.11.0-rc2+dev-00006-gf68ade529-dirty (2021-02-13-02:12)\""
	$OPENOCD --vers 2>&1|head -1
	echo
	echo "# $GCC_PATH/arm-none-eabi-gcc --vers"
	echo "## NOTE: works (on 20210505) with: \"arm-none-eabi-gcc (GNU Arm Embedded Toolchain 10-2020-q4-major) 10.2.1 20201103 (release)\""
	$GCC_PATH/arm-none-eabi-gcc --vers|head -1
	
	echo
	echo "1.5) git"
	_mySanityCheckGit

	echo
	echo "1.6) List 'openocd' process"
	_mySanityCheckOpenocd

	echo
	echo "1.7) Debugger"
	echo "# Debugger = ${debugger} (mandatory: filled)"
	_mySanityCheckDebugger
	echo
	echo "# Ex. details for 'STLink-V2' and Oracle VM VirtualBox"
	echo "## USB 'ST-LINK V2' device  : Led *should* remains fixed blue (else: reboot host/VM)"
	echo "## Oracle VirtualBox GUI    : Checked 'Devices/USB/STMicroelectronics STM32 STLink [0100]'"
	echo "## Ubuntu Linux OS /dev/    : ls -l /dev/|grep stlink (ex: 'stlinkv2_2 -> bus/usb/001/004')"

	echo
	#echo "# WARNING: If get any error: check your git version, path install for OpenOCD & GCC, G&W Up & powered, STLink USB & cables connected, led not blinking..."
}

# =================================================
function _UpdateGWMakeGitFlashloader() {
	echo "# git pull https://${URL_flashloader} + make clean + make"
	echo
	_myPause
	cd ../game-and-watch-flashloader
	git status
	git reset --hard
	git status
	git pull https://${URL_flashloader}
	git submodule update --init --recursive
	echo "# make clean"
	time make clean
	echo "# make -j$nproc"
	time make -j$nproc
	cd -
}
# -------------------------------------------------
function _UpdateGWApplymyPatch() {
	echo
	echo "# Patch interface_stlink.cfg (> speed down to 200)"
	echo
	_myPause
	cp ../game-and-watch-flashloader/interface_stlink.cfg ../game-and-watch-mytools/interface_stlink.cfg_ORIG
	cp ../game-and-watch-mytools/interface_stlink.cfg ../game-and-watch-flashloader
	echo "# Check"
	sdiff ../game-and-watch-mytools/interface_stlink.cfg_ORIG ../game-and-watch-flashloader/interface_stlink.cfg
}
# -------------------------------------------------
function _UpdateGWMakeGitRetroGo() {
	echo "# git pull https://${URL_retrogo} + make clean + make"
	echo
	_myPause
	git status
	git reset --hard
	git pull https://${URL_retrogo}
	git submodule update --init --recursive
	echo "# make clean"
	time make clean
	# EXTFLASH_SIZE_MB=$extflashMB 
	echo "# make -j$nproc COMPRESS=$compress GNW_TARGET=$gnwtarget CHECK_TOOLS=$checktools ENABLE_SCREENSHOT=$screenshot"
	time make -j$nproc COMPRESS=$compress GNW_TARGET=$gnwtarget CHECK_TOOLS=$checktools ENABLE_SCREENSHOT=$screenshot
}
# -------------------------------------------------
function _UpdateGWMakeFlashRetroGoRom() {
	# EXTFLASH_SIZE_MB=$extflashMB
	echo "# Exec. ? = \`time make -j$nproc COMPRESS=$compress GNW_TARGET=$gnwtarget CHECK_TOOLS=$checktools ENABLE_SCREENSHOT=$screenshot flash\`"
	echo
	_myPause
	# Deprecated: time make -j$nproc flash_all
	# make clean
	time make -j$nproc COMPRESS=$compress GNW_TARGET=$gnwtarget CHECK_TOOLS=$checktools ENABLE_SCREENSHOT=$screenshot flash
	echo
}

# =================================================
function _RomsGWListAll() {
	retrogo_Roms_Folder=`pwd`
	cd $Roms_Folder
	# find . -name *\*| grep -ie sms$ -ie nes$ -ie pce$ -ie gg$ -ie gb$ | more
	# du -hc .| grep total
	OPTION=$(whiptail --nocancel \
		--title "Game & Watch retro-go" \
		--menu "\nChoose a rom folder :" 15 60 6 \
		"1" " gb" \
		"2" " gg" \
		"3" " nes" \
		"4" " pce" \
		"5" " sms" \
		" " " Exit" 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus = 0 ]; then
		case $OPTION in
			1)	echo "# Gameboy roms"
				tree -s --noreport ./gb ; du -s -b ./gb
				# du -a -b ./gb|grep -ie gb$ -ie gbc$
				# find . -name *\*| grep -ie gg$ -ie gb$ | more
				;;
			2)	echo "# GameGear roms"
				tree -s --noreport ./gg ; du -s -b ./gg
				# du -a -b ./gg|grep -ie gg$
				# find . -name *\*| grep -ie gg$ -ie gb$ | more
				;;
			3)	echo "# NES roms"
				tree -s --noreport ./nes ; du -s -b ./nes
				# du -a -b ./nes| grep -ie nes$
				;;
			4)	echo "# PCEngine roms"
				tree -s --noreport ./pce ; du -s -b ./pce
				# du -a -b ./pce| grep -ie pce$
				;;
			5)	echo "# SMS roms"
				tree -s --noreport ./sms ; du -s -b ./sms
				# du -a -b ./sms| grep -ie sms$
				;;
			" ")	echo "Exit..." ;;
		esac
	fi
	# cd - 2>/dev/null
	cd $retrogo_Roms_Folder 2>/dev/null
}
# -------------------------------------------------
function _RomsGWListLocalAndSaveStates() {
	echo
	echo "# Local size & date of ./save_states files"
	#find ./save_states -name *.save
	#ls -ltr save_states/*/*.save|sed "s/ 1 ubuntu ubuntu //g"
	ls -ltr save_states/*/*.save|cut -c28-
	#echo "# md5sum ./save_states files"
	#find . -name *.save -exec md5sum {} \;
	echo
	_RomsGWListSize
	echo
}
# -------------------------------------------------
function _RomsGWListSize() {
	echo "# Local size of ./roms files"
	# ls -lR ./roms
	# for emu in gb nes gg sms pce; do 
		# stat -c "%s %n" roms/${emu}/* 2>/dev/null
	# done
	tree -s --noreport ./roms
	du -c -b ./roms|grep "total"
	# du -c -b ./roms/*/*.${compress}|sed "s/total/total (.${compress} only)/g"|grep "total"
	du -c -b ./roms/*/*.lz4|sed "s/total/total (.lza only)/g"|grep "total"
	du -c -b ./roms/*/*.lzma|sed "s/total/total (.lzma only)/g"|grep "total"
	du -c -b ./roms/*/*.zopfli|sed "s/total/total (.zopfli only)/g"|grep "total"
}
# -------------------------------------------------
function _RomsGWShell() {
	retrogo_Roms_Folder=`pwd`
	_RomsGWListSize
	echo
	echo "# Roms folders"
	# echo "## retro-go local Rom_Folder = ${retrogo_Roms_Folder}"
	echo "## all roms Rom_Folder	   = ${Roms_Folder}"
	echo "## check local rom size	   = tree -s ; du -s -b ; du -c -b *.${compress}|grep total" 
	echo
	echo "# Note: run 'exit' or 'Ctrl+D' to go back in script"
	export gg=${Roms_Folder}/gg
	export gb=${Roms_Folder}/gb
	export nes=${Roms_Folder}/nes
	export pce=${Roms_Folder}/pce
	export sms=${Roms_Folder}/sms
	cd $retrogo_Roms_Folder 2>/dev/null
	echo
	cd $retrogo_Roms_Folder/roms ; /bin/bash
	cd - 2>/dev/null
	echo
}

# =================================================
function _SavesRestore() {
	echo "# ./scripts/saves_restore.sh build/gw_retro_go.elf"
	_myPause
	# time ./program_saves.sh build/gw_retro_go.elf
	time ./scripts/saves_restore.sh build/gw_retro_go.elf
}
# -------------------------------------------------
function _SavesBackup() {
	echo "# Make sur using the SAME build/gw_retro_go.elf file used to in step Build and Flash to G&W"
	# echo "# ./dump_saves.sh build/gw_retro_go.elf"
	echo "# ./scripts/saves_backup.sh build/gw_retro_go.elf"
	_myPause
	find . -name *.save -exec md5sum {} \; > ../game-and-watch-mytools/md5sum.save_before
	# ./dump_saves.sh build/gw_retro_go.elf
	time ./scripts/saves_backup.sh build/gw_retro_go.elf
	find . -name *.save -exec md5sum {} \; > ../game-and-watch-mytools/md5sum.save_after
	echo
	echo "# sdiff md5sum ./save_states files (before vs after)"
	# sdiff ../game-and-watch-mytools/md5sum.save_before ../game-and-watch-mytools/md5sum.save_after
	diff ../game-and-watch-mytools/md5sum.save_before ../game-and-watch-mytools/md5sum.save_after|grep ">"
}

# =================================================
function _BackupBuildAndRomsAsSav() {
	export BKP_FolderDate=${BKP_Folder}/`date +'%Y%m%d_%H%M%S'`.sav
	echo "# Fast save"
	echo
	echo "# ${BKP_NbToList} Last backups from $BKP_Folder"
	ls -ltr $BKP_Folder|tail -${BKP_NbToList}
	echo
	echo "# Last local save(s) (sdiff md5sum ./save_states files (before vs after))"
	# sdiff ../game-and-watch-mytools/md5sum.save_before ../game-and-watch-mytools/md5sum.save_after
	diff ../game-and-watch-mytools/md5sum.save_before ../game-and-watch-mytools/md5sum.save_after|grep ">"
	echo
	echo "# Backup local .sav files to $BKP_Folder folder ?"
	_myPause
	echo "# Create $BKP_FolderDate"
	mkdir -p $BKP_FolderDate 2>/dev/null
	mkdir -p $BKP_FolderDate/build 2>/dev/null
	echo "# Backup ./game-and-watch.git logs"
	echo "# local  git log game-and-watch-flashloader: `git --git-dir ../game-and-watch-flashloader/.git log|sed "s/commit //g"|head -3`" > $BKP_FolderDate/game-and-watch.git
	echo "# local  git log game-and-watch-retro-go: `git log|sed "s/commit //g"|head -3`" >> $BKP_FolderDate/game-and-watch.git
	echo "# Backup ./build/gw_retro_go*.* files"
	cp --preserve=timestamps build/gw_retro_go*.* $BKP_FolderDate/build
	echo "# Backup ./roms files"
	cp -R --preserve=timestamps roms/ $BKP_FolderDate
	echo "# Backup ./save_states files"
	cp -R --preserve=timestamps save_states/ $BKP_FolderDate

	export FolderName=`ls -ltr ${BKP_Folder}|grep -v "\./"|tail -1|awk '{print $NF}'|sed "s/\/$//g"`
	NewFolderName=$(whiptail --title "Change .sav folder name ?" --inputbox "\n$BKP_FolderDate\n\nChange folder name ?\n> Enter to validate your changes\n> Esc to cancel" 13 40 "$FolderName" 3>&1 1>&2 2>&3)
	exitstatus=$?
	# echo "# Change .save folder name ?"
	if [ $exitstatus = 0 ] && [ "$FolderName" != "$NewFolderName" ]; then
		mv -f ${BKP_Folder}/$FolderName "${BKP_Folder}/$NewFolderName"
		echo "# Save state folder renamed as:" ${BKP_Folder}/$NewFolderName
	else
		echo "# Save state folder name unchanged:" ${BKP_Folder}/$FolderName
	fi
	echo "# List ${BKP_NbToList} lasts backups folders from ${BKP_Folder}"
	ls -ltr ${BKP_Folder}|grep -v "\./"|tail -${BKP_NbToList}
}
# -------------------------------------------------
function _BackupGWFolderAsTgz() {
	export BKP_FolderDate=${BKP_Folder}/`date +'%Y%m%d_%H%M%S'`.tgz
	git_github=`git ls-remote git://${URL_retrogo}|head -1|awk '{print $1}'`
	git_local=`git log|sed "s/commit //g"|head -1`
	if [ "$git_github" == "$git_local" ] ; then git_cmp=" (OK)" ; else git_cmp=" (KO: older)"; fi
	echo "# Source: https://${URL_retrogo}"
	echo "## github git log game-and-watch-retro-go:	$git_github"
	echo "## local	git log game-and-watch-retro-go:	$git_local ${git_cmp}"
	echo "	 `git log|sed "s/commit //g"|head -3|tail -1`"
	echo
	bkp_lst=`ls -l $BKP_Folder/*.tgz|grep /mnt/share/bkp|sed "s/://g"|tail -1` 
	echo "# Last git bkp $bkp_lst"
	cat $bkp_lst/game-and-watch.git|grep -e local -e Date|sed "s/Date:/	  Date:/g"|sed "s/# local/## local/g"|sed "s/retro-go:/retro-go:   /g"|tail -2
	ls -l $bkp_lst
	echo
	echo "# WARNING: Bkp may takes 2+ minutes..."
	_myPause

	mkdir -p $BKP_FolderDate 2>/dev/null
	echo "# Get folders git commit ids"
	echo "# local  git log game-and-watch-backup: `git --git-dir ../game-and-watch-backup/.git log|sed "s/commit //g"|head -4`" > $BKP_FolderDate/game-and-watch.git
	echo "# local  git log game-and-watch-flashloader: `git --git-dir ../game-and-watch-flashloader/.git log|sed "s/commit //g"|head -4`" >> $BKP_FolderDate/game-and-watch.git
	echo "# local  git log game-and-watch-retro-go: `git log|sed "s/commit //g"|head -4`" >> $BKP_FolderDate/game-and-watch.git

	echo "# Process game-and-watch-mytools.tgz"
	cp ../game-and-watch-mytools/retro-go.sh ../game-and-watch-mytools/retro-go.sh_ORIG
	cp retro-go.sh ../game-and-watch-mytools
	tar -czf ${BKP_FolderDate}/game-and-watch-mytools.tgz ../game-and-watch-mytools/ 2>/dev/null
	echo "# Process game-and-watch-backup_<git commit id>.tgz"
	tar -czf ${BKP_FolderDate}/game-and-watch-backup_`git --git-dir ../game-and-watch-backup/.git log|head -1|cut -b8-14`.tgz ../game-and-watch-backup/ 2>/dev/null
	echo "# Process game-and-watch-flashloader_<git commit id>.tgz"
	tar -czf ${BKP_FolderDate}/game-and-watch-flashloader_`git --git-dir ../game-and-watch-flashloader/.git log|head -1|cut -b8-14`.tgz ../game-and-watch-flashloader/ 2>/dev/null
	echo "# Process game-and-watch-retro-go_<git commit id>.tgz"
	tar -czf ${BKP_FolderDate}/game-and-watch-retro-go_`git log|head -1|cut -b8-14`.tgz ../game-and-watch-retro-go/ 2>/dev/null

	echo "# List ${BKP_NbToList} lasts backups folders from ${BKP_Folder}"
	ls -ltr ${BKP_Folder}|grep -v "\./"|tail -${BKP_NbToList}
}

# =================================================
function _BackupListFolder() {
	ls -ltr $BKP_Folder
	du -hc $BKP_Folder| grep total
	ls -ltr $BKP_Folder|wc -l
}
# -------------------------------------------------
function _ScreenshotDump() {
	# For screenshot:
	## sudo apt-get update
	## sudo apt-get install python-pyelftools
	## sudo apt install python3-pip => OK
	## sudo pip install pyelftools => OK
	# Then, for manual screenshots:
	## Open 2 Bash
	## Perform : export OPENOCD=/opt/openocd-git/bin/openocd;export GCC_PATH=/home/ubuntu/game-and-watch/gcc-arm-none-eabi-10-2020-q4-major/bin/;export PATH=$GCC_PATH:$PATH
	## Bash 1  : make openocd (and keep it running)
	## Bash 2  : make dump_screenshot
	if [ "-#${screenshot}#-" == "-#1#-" ] ; then
		echo "# make dump_screenshot"
		time make dump_screenshot
		echo
		_ScreenshotList
	else
		echo
		echo "# make dump_screenshot KO: needs needs: ENABLE_SCREENSHOT=1"
	fi
}
# -------------------------------------------------
function _ScreenshotDumpFullVar() {
	# EXTFLASH_SIZE_MB=$extflashMB
	echo "# make -j$nproc COMPRESS=$compress GNW_TARGET=$gnwtarget CHECK_TOOLS=$checktools ENABLE_SCREENSHOT=$screenshot dump_screenshot"
	time make -j$nproc COMPRESS=$compress GNW_TARGET=$gnwtarget CHECK_TOOLS=$checktools ENABLE_SCREENSHOT=$screenshot dump_screenshot
	echo
	_ScreenshotList
}
# -------------------------------------------------
function _ScreenshotList() {
	echo "# date"
	date
	echo "# screenshot list"
	ls -ltr screenshot*.png|tail -2
	echo
	echo "# Show last screenshot (eog)"
	eog `ls -tr screenshot*.png|tail -1`
}
# -------------------------------------------------
function _ScreenshotBkp() {
	echo "# Create $Scr_Folder"
	mkdir -p $Scr_Folder 2>/dev/null
	echo "# mv screenshot*.bin to ${Scr_Folder}"
	mv screenshot*.bin ${Scr_Folder}
	echo "# mv screenshot*.png to ${Scr_Folder}"
	mv screenshot*.png ${Scr_Folder}
}

# =================================================
function _KillOpenocd() {
	echo "# List 'openocd' process"
	ps -e|grep openocd
	echo
	export openocdPID=`ps -ef|grep openocd|grep -v grep|grep "\-c init; halt"|awk '{print $2}'`
	echo "# Kill 'openocd' process (${openocdPID}) ?"
	echo
	_myPause
	kill ${openocdPID}
	echo
	sleep 2
	echo "# Check (again) 'openocd' process"
	ps -e|grep openocd
	echo
	# _myPause
}

# =================================================
function _MiscOptions() {
	OPTION=$(whiptail --nocancel \
		--title "Game & Watch retro-go Options" \
		--menu "\nChoose an action :" 32 90 23 \
		 "0" " ? Full Sanity check                           (env., git, OpenOCD & GCC)" \
		 ""  "" \
		 "1" " # List share available roms                 (all: gb, gg, nes, pce, sms)" \
		 "2" " ? List local ./save_states & ./roms                            (current)" \
		 "3" " * Open 'shell' to copy roms locally" \
		 ""  "" \
		 "4" " + Backup ./build (~.elf) & ./roms & ./save_states                 (.sav)" \
		 "5" " + Backup folders game-and-watch-* (~.git)                         (.tgz)" \
		 "6" " + Backup (move) screenshots                                (.bin & .png)" \
		 "7" " ? List all performed backups                               (.sav & .tgz)" \
		 "8" " ? List 2 lasts local screenshots                                  (.png)" \
		 ""  "" \
		 "9" " ? Show 'make help'" \
		"10" " ? List retro-go Keys & Macro" \
		""   "" \
		"11" " # Query Debugger Adapter                 (ST-Link, J-Link, Raspberry pi)" \
		""   "" \
		"12" " ? Ubuntu mandatory packages list" \
		"13" " x List & Kill any 'openocd' process" \
		"14" " x Clean retro-go                                            (make clean)" \
		"15" " x Reset the unit                                        (make reset_mcu)" \
		""   "" \
		" " " Back to main menu" 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus = 0 ]; then
		case $OPTION in
			# -------------------------------------------------
			0)	_mySeparator
				echo "0) Sanity Check"
				_mySanityCheck
			;;

			# -------------------------------------------------
			1)	_mySeparator
				echo "1) List all roms (gb, gg, nes, pce, sms) from: $Roms_Folder"
				_RomsGWListAll
			;;

			# -------------------------------------------------
			2)	_mySeparator
				echo "2) List local ./roms & ./save_states files"
				_RomsGWListLocalAndSaveStates
			;;
			
			# -------------------------------------------------
			3)	_mySeparator
				echo "3) Shell to rom folder $Roms_Folder"
				_RomsGWShell
			;;

			# -------------------------------------------------
			4)	_mySeparator
				echo "4) Backup ./build (.elf) & ./roms & ./save_states files to ${BKP_Folder}/<DATE>_<TIME>"
				_BackupBuildAndRomsAsSav
			;;

			# -------------------------------------------------
			5)	_mySeparator
				echo "5) Backup game-and-watch (.tgz) folders to ${BKP_Folder}/<DATE>_<TIME>"
				_BackupGWFolderAsTgz
			;;

			# -------------------------------------------------
			6)	_mySeparator
				echo "6) Backup screenshots (.png)"
				# _myPause
				_ScreenshotBkp
			;;

			# -------------------------------------------------
			7)	_mySeparator
				echo "7) List all backups from: $BKP_Folder"
				_myPause
				_BackupListFolder
			;;

			# -------------------------------------------------
			8)	_mySeparator
				echo "8) List local screenshots"
				# _myPause
				_ScreenshotList
			;;

			# -------------------------------------------------
			9)	_mySeparator
				echo "9) Show 'make help'"
				# _myPause
				make help
			;;

			# -------------------------------------------------
			10)	_mySeparator
				echo "10) Retro-go Keys & Macros"
				_myRetroGoKeys
			;;

			# -------------------------------------------------
			11)	_mySeparator
				echo "11) Query Debugger Adapter (ST-Link, J-Link, Raspberry pi)"
				echo "# Current"
				echo "## ADAPTER      = $ADAPTER"
				_myPause
				_QueryDebuggerAdapter
				echo
				echo "# New"
				echo "## ADAPTER      = $ADAPTER"
			;;

			# -------------------------------------------------
			12)	_mySeparator
				echo "12) Ubuntu mandatory packages list"
				cat UbuntuInstall.txt
				# _myPause
			;;

			# -------------------------------------------------
			13)	_mySeparator
				echo "13) Kill 'openocd' process"
				# _myPause
				_KillOpenocd
			;;

			# -------------------------------------------------
			14)	_mySeparator
				echo "14) make clean"
				_myPause
				time make clean
			;;

			# -------------------------------------------------
			15)	_mySeparator
				echo "15) Reset the unit ?"
				echo "# make reset_mcu"
				 _myPause
				make reset_mcu
				echo "# reset done"
			;;

			" ")	echo "# Exit...";;
		esac
	else
		echo "Exit(ESC)..."
	fi
	# if [[ $OPTION != " " ]]; then
		# _myPause
	# fi
}


# =================================================
# SELECT USB DEBUGGER TO G&W
# =================================================
stay=true
function _QueryDebuggerAdapter() {
	OPTION=$(whiptail --nocancel \
		--title "Game & Watch retro-go" \
		--menu "\nChoose a debugger :" 15 60 6 \
		"1" " ST-Link" \
		"2" " J-Link" \
		"3" " Raspberry pi" \
		"" " " \
		" " " Exit" 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus = 0 ]; then
		case $OPTION in
			1)	debugger=stlink ;;
			2)	debugger=jlink ;;
			3)	debugger=rpi ;;
			" ")	echo "Exit..." & stay=false ;;
		esac
	else
		echo "Exit(ESC)..."
		stay=false
	fi
	export ADAPTER=$debugger
}
if	[ "$ADAPTER" == "" ] ; then
	_QueryDebuggerAdapter
fi



# =================================================
# SELECT G&W [mario|zelda]
# =================================================
stay=true
function _QueryGnW() {
	OPTION=$(whiptail --nocancel \
		--title "Game & Watch model" \
		--menu "\nChoose a G&W (mario|zelda) :" 14 60 4 \
		"1" " mario" \
		"2" " zelda" \
	 	""  "" \
		" " " Exit" 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus = 0 ]; then
		case $OPTION in
			1)	gnwtarget=mario ;;
			2)	gnwtarget=zelda ;;
			" ")	echo "Exit..." & stay=false ;;
		esac
	else
		echo "Exit(ESC)..."
		stay=false
	fi
	export GNW_TARGET=$gnwtarget 
}
_QueryGnW

# =================================================
# MAIN MENU
# =================================================
while [ $stay = true ]
do
	OPTION=$(whiptail --nocancel \
	--title "Game & Watch retro-go" \
	--menu "\nChoose an action :" 23 90 14 \
	 "0" " ? Quick Sanity check" \
	 "1" " # Misc. options sub-menu" \
	 ""  "" \
	 "2" " * git Update game-and-watch-flashloader            (git pull+clean+make)" \
	 "3" " * Patch interface_stlink.cfg                         (adapter speed 200)" \
	 "4" " * git Update game-and-watch-retro-go               (git pull+clean+make)" \
	 ""  "" \
	 "5" " * Build (retro-go+rom) & flash *to* G&W                     (make flash)" \
	 "6" " < Restore Save states *to*   G&W                      (saves_restore.sh)" \
	 ""  "" \
	 "7" " > Backup  Save states *from* G&W                       (saves_backup.sh)" \
	 "8" " > Backup  Screenshot  *from* G&W                  (make dump_screenshot)" \
	 ""  "" \
	 " " " Exit" 3>&1 1>&2 2>&3)
	 # "4" " * git Update game-and-watch-retro-go               (git pull+clean+make)" \
	 # "8" " > Backup  Screenshot  *from* G&W            (needs: ENABLE_SCREENSHOT=1)" \

	exitstatus=$?
	if [ $exitstatus = 0 ]; then
		case $OPTION in
		# -------------------------------------------------
		1)	_mySeparator
			echo "1) Misc. options sub-menu"
			# _myPause
			_MiscOptions
		;;

		# -------------------------------------------------
		0)	_mySeparator
			echo "0) Quick Sanity check"
			# _myPause
			_mySanityCheckListVar
			echo
			_mySanityCheckGit
			echo
			_mySanityCheckOpenocd
			echo
			echo "# Debugger = ${debugger} (mandatory: filled)"
			_mySanityCheckDebugger
			echo
		;;

		# -------------------------------------------------
		2)	_mySeparator
			echo "2) Update game-and-watch-flashloader (git pull+clean+make) ?"
			_myPause
			_UpdateGWMakeGitFlashloader
		;;

		# -------------------------------------------------
		3)	_mySeparator
			echo "3) Apply myPatch(s) ?"
			_myPause
			_UpdateGWApplymyPatch
		;;

		# -------------------------------------------------
		4)	_mySeparator
			echo "4) Update game-and-watch-retro-go (git pull+clean+make) ?"
			_myPause
			_UpdateGWMakeGitRetroGo
		;;

		# -------------------------------------------------
		5)	_mySeparator
			echo "5) Build and Flash (retro-go + roms) to G&W ? (make flash)"
			echo
			echo "# size of ./roms files"
			# for emu in gb nes gg sms pce; do 
				# stat -c "%s %n" roms/${emu}/* 2>/dev/null
			# done
			tree -s --noreport ./roms
			du -c -b ./roms|grep "total" 
			du -c -b ./roms/*/*.${compress}|sed "s/total/total (.${compress} only)/g"|grep "total" 
			echo
			_mySanityCheckListVar
			echo
			echo "# Note:"
			echo "## Before flash: If change one command line parameter (COMPRESS, SCREENSHOT, ...), perform a 'make clean' first"
			echo "## After  flash: If get any red error message like: 'Flashing chunk 0 failed... power cycle unit and retry? (y/n)'"
			echo "##               Then 'Build and Flash (retro-go + roms)' again!"
			echo
			_UpdateGWMakeFlashRetroGoRom
			_RomsGWListSize
		;;

		# -------------------------------------------------
		6)	_mySeparator
			echo "6) Restore local save states to G&W"
			# _myPause
			_SavesRestore
		;;

		# -------------------------------------------------
		7)	_mySeparator
			echo "7) Backup locally save states from G&W"
			# _myPause
			_SavesBackup
		;;

		# -------------------------------------------------
		8)	_mySeparator
			echo "8) Save Screenshot locally *from* G&W" 
			# _myPause
			_ScreenshotDump
		;;

		# -------------------------------------------------
		" ") echo "Exit..."
			stay=false
		;;
		
		esac
		
		if [[ $OPTION != " " ]]; then
			_myPause
		fi
	else
		echo "Exit(ESC)..."
		stay=false
	fi
done
