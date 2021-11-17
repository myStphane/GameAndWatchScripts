#!/bin/bash
# Source: https://github.com/ghidraninja/game-and-watch-backup/
# Script: 20211107
# Owners: Zba & myStph

export OPENOCD=/opt/openocd-git/bin/openocd

debugger=
stay=true

function _mySeparator() {
        echo
        echo "# --------------------------------------------------------------------------------------------------"
}

# =================================================
# SELECT Debugger
# =================================================
OPTION=$(whiptail --nocancel \
        --title "Game & Watch backup" \
        --menu "\nChoose a debugger :" 15 60 6 \
        "1" " ST Link" \
        "2" " J-Link" \
        "3" " Raspberry pi" \
        "" " " \
        " " " Exit" 3>&1 1>&2 2>&3)
exitstatus=$?
if [ $exitstatus = 0 ]; then
        case $OPTION in
                1) debugger=stlink ;;
                2) debugger=jlink ;;
                3) debugger=rpi ;;
                " ") echo "Exit..."
                     stay=false
                ;;
        esac
else
        echo "Exit(ESC)..."
        stay=false
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
                        1)      gnwtarget=mario ;;
                        2)      gnwtarget=zelda ;;
                        " ")    echo "Exit..." & stay=false ;;
                esac
        else
                echo "Exit(ESC)..."
                stay=false
        fi
        export GNW_TARGET=$gnwtarget
}
_QueryGnW

# =================================================
# Main loop
# =================================================
                #"7" " - Restore flash (ex. whenever err. step 3) (deprecated)" \
while [ $stay = true ]
do
        OPTION=$(whiptail --nocancel \
                --title "Game & Watch backup" \
                --menu "\nChoose an action :" 23 80 13 \
                "0" " ? my Local Sanity & Notes" \
		""  " " \
                "1" " Sanity Check" \
                "2" " Backup Flash" \
                "3" " Backup Internal Flash" \
                "4" " Unlock Device" \
                "5" " Restore" \
		""  " " \
                "6" " - Restore flash (ex. whenever err. step 3)" \
                "8" " * Update git" \
		""  " " \
                " " " Exit" 3>&1 1>&2 2>&3)
        exitstatus=$?
        if [ $exitstatus = 0 ]; then
                case $OPTION in
                        0)	_mySeparator
                                echo "0) my Local Sanity & Notes..."
				echo
                                git_github=`git ls-remote git://github.com/ghidraninja/game-and-watch-backup|head -1|awk '{print $1}'`
                                git_local=`git --git-dir ./.git log|sed "s/commit //g"|head -1`
                                if [ "$git_github" == "$git_local" ] ; then git_cmp=" (OK)" ; else git_cmp=" (KO: older)"; fi
                                echo "# Source: https://github.com/ghidraninja/game-and-watch-backup"
                                echo "## github git log: $git_github"
                                echo "## local  git log: $git_local ${git_cmp}"
				echo
                                echo "# debugger     = $debugger"
                                echo "# gnwtarget    = $gnwtarget"
                                echo "# OPENOCD      = $OPENOCD"
				ls -l $OPENOCD

				echo
				# echo "# How to verify backup SHA1 sums"
				# echo "## You can verify the backup using the included SHA1 sums located in game-and-watch-backup/shasums"
				# echo "## Discord link: https://discord.com/channels/781528730304249886/783282561001717771/825325928028438538"
                                echo "# STLink-V2 and Oracle VM VirtualBox"
                                echo "## USB 'ST-LINK V2' device: Led *should* remains fixed blue (else: reboot host/VM)"
                                echo "## GUI VirtualBox         : Checked 'Devices/USB/STMicroelectronics STM32 STLink [0100]'"
                                echo "## Ubuntu Linux OS        : ls -l /dev/|grep ${debugger} (ex: 'stlinkv2_2 -> bus/usb/001/004')"
                                ls -la /dev/|grep ${debugger}
				echo "## WARNING: previous line should NOT be empty! (else, check you debugger)"

				echo
				echo "# NOTES:"
                                echo "## If get any error: check your git version, path install, G&W Up & powered, STLink USB & cables connected, led not blinking..."
				echo "## Carefully check your probe connections: on G&W debug ports, on the ${debugger} device side, on the host where USB is connected"
				echo "## Possibly, lower you probe speed connection"
				echo "### in file : openocd/interface_${debugger}.cfg"
				echo "### update  : from 500 down to 100"
				echo
                        ;;

                        1)	_mySeparator
                                echo "1) Sanity check..."
                                ./1_sanity_check.sh
                        ;;

                        2)	_mySeparator
                                echo "2) Backup Flash"
                                echo "# ./2_backup_flash.sh $debugger $gnwtarget"
                        	read -p "Press [ENTER] to process"
                                ./2_backup_flash.sh $debugger $gnwtarget
                        ;;

                        3)	_mySeparator
                                echo "3) Backup Internal Flash"
                                echo "# ./3_backup_internal_flash.sh $debugger $gnwtarget"
                        	read -p "Press [ENTER] to process"
                                ./3_backup_internal_flash.sh $debugger $gnwtarget
                        ;;

                        4)	_mySeparator
                                echo "4) Unlock Device"
                                echo "# ./4_unlock_device.sh $debugger $gnwtarget"
                        	read -p "Press [ENTER] to process"
                                ./4_unlock_device.sh $debugger $gnwtarget
                        ;;

                        5)	_mySeparator
                                echo "5) Restore"
                                echo "# ./5_restore.sh $debugger $gnwtarget"
                        	read -p "Press [ENTER] to process"
                                ./5_restore.sh $debugger $gnwtarget
                        ;;

			6)	_mySeparator
				echo "6) Restore flash (Something goes wrong during Step 3)"
				echo "# ./restore_only_external_flash.sh $debugger $gnwtarget"
                        	read -p "Press [ENTER] to process"
				./restore_only_external_flash.sh $debugger $gnwtarget
                        ;;

			7)	_mySeparator
				echo "7) Restore flash (ex. whenever get err. on step 3) / Deprecated: G&W mario"
				echo "# ./scripts/flashloader.sh $debugger ./backups/flash_backup.bin"
                        	read -p "Press [ENTER] to process"
				echo "# 1. Maintain the *Power Button* pressed"
                        	read -p "Press [ENTER] to continue"
				echo "# 2. Restore flash on-going..."
				./scripts/flashloader.sh $debugger ./backups/flash_backup.bin
				echo "# 3. Once done, release the *Power Button* and process again with you failed step..."
                        ;;

			8)	_mySeparator
				echo "8) Update git from https://github.com/ghidraninja/game-and-watch-backup"
                        	read -p "Press [ENTER] to process"
                                git status
                                git reset --hard
                                git status
                                git pull https://github.com/ghidraninja/game-and-watch-backup
                                git submodule update --init --recursive
			;;

                        " ")
                                echo "Exit..."
                                stay=false
                        ;;
                esac
                if [[ $OPTION != " " ]]; then
                        read -p "Press [ENTER] to continue"
                fi
        else
                echo "Exit(ESC)..."
                stay=false
        fi
done
