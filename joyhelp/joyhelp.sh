#!/bin/sh -e
# joyswap.sh
# ~/RetroPie/retropiemenu/joyswap.sh

# Joystick / Controller utility for RetroPie
# I use xboxdrv and xpad and have a collection of scripts to manage them.
# I wanted an easy way to write one config file and be able to lauch xboxdrv in different ways.
#
# Includes a quick and dirty way to swap port 1 and 2 in RetroPie/RetroArch.
#
# The swap joystick 1 and 2 mode edits the main retroarch.cfg (it backs it up to retroarch.cfg.bup first!)
# It requires that the "input_player1_joypad_index" and "input_player2_joypad_index" be set.
# mine usually looks like this:
#	input_player1_joypad_index = "0"
# 	input_player2_joypad_index = "1"
# 	input_player3_joypad_index = "2"
# 	input_player4_joypad_index = "3"

# JOYHELP DIRECTORIES
# maybe these could change...
CONFIGDIR=/opt/retropie/configs/all
XBDRDIR=$CONFIGDIR/joyhelp

# Don't Change These
XBOXMGR=$XBDRDIR/joyhelp-enable.cfg
RACONFIGFILE=$CONFIGDIR/retroarch.cfg
LOGFILE=$XBDRDIR/xdrv.log

MODE=$(cat "$XBOXMGR" | head -c1)
ABLE=$(cat $XBOXMGR | tail -n +2)

INTERACTIVE=True
ASK_TO_REBOOT=0
WT_WIDTH=80
WT_WIDTH=120
WT_MENU_HEIGHT=$(($WT_HEIGHT-7))

dbg=0;
# figure out if we have debug (write to log) enabled.
if [ "$MODE" = "5" ] || [ "$MODE" = "6" ] || [ "$MODE" = "7" ] || [ "$MODE" = "8" ] || [ "$MODE" = "9" ]
then
	dbg=1
fi
if [ "$dbg" = "1" ]; then echo "joyswap: running - $(date)" >> $LOGFILE; fi

calc_wt_size() {
  # NOTE: it's tempting to redirect stderr to /dev/null, so supress error 
  # output from tput. However in this case, tput detects neither stdout or 
  # stderr is a tty and so only gives default 80, 24 values
  WT_HEIGHT=17
  WT_WIDTH=$(tput cols)

  if [ -z "$WT_WIDTH" ] || [ "$WT_WIDTH" -lt 60 ]; then
    WT_WIDTH=80
  fi
  if [ "$WT_WIDTH" -gt 178 ]; then
    WT_WIDTH=120
  fi
  WT_MENU_HEIGHT=$(($WT_HEIGHT-7))
}

do_about() {
  whiptail --msgbox "\
This tool is used to help manage xboxdrv config \
files and allows easy changing between daemon and\
non-daemon modes (without you having to write a \
new conf file.)\
" 20 70 1
}

do_finish() {
  if [ $ASK_TO_REBOOT -eq 1 ]; then
    whiptail --yesno "Would you like to reboot now? you really should if you made any changes or things can get weird." 20 60 2
    if [ $? -eq 0 ]; then # yes
      sync
      reboot
    fi
  fi
  exit 0
}

do_mode_disable() {
# $XBOXMGR
if [ "$dbg" = "1" ]; then echo "joyswap: mode: disabled" >> $LOGFILE; fi

if [ $dbg = 1 ]; then
MODE=5
else
MODE=0
fi
echo "$MODE" > $XBOXMGR
echo "$ABLE" >> $XBOXMGR
ASK_TO_REBOOT=1
}

do_mode_auto() {
# $XBOXMGR
if [ "$dbg" = "1" ]; then echo "joyswap: mode: auto" >> $LOGFILE; fi
if [ $dbg = 1 ]; then
MODE=6
else
MODE=1
fi
echo "$MODE" > $XBOXMGR
echo "$ABLE" >> $XBOXMGR
ASK_TO_REBOOT=1

}

do_mode_nodaemon() {
# $XBOXMGR
if [ "$dbg" = "1" ]; then echo "joyswap: mode: NO daemon" >> $LOGFILE; fi
if [ $dbg = 1 ]; then
MODE=7
else
MODE=2
fi
echo "$MODE" > $XBOXMGR
echo "$ABLE" >> $XBOXMGR
ASK_TO_REBOOT=1
}

do_mode_daemon() {
# $XBOXMGR
if [ "$dbg" = "1" ]; then echo "joyswap: mode: daemon" >> $LOGFILE; fi
if [ $dbg = 1 ]; then
MODE=8
else
MODE=3
fi
echo "$MODE" > $XBOXMGR
echo "$ABLE" >> $XBOXMGR
ASK_TO_REBOOT=1
}

do_mode_ingameonly() {
# $XBOXMGR
if [ "$dbg" = "1" ]; then echo "joyswap: mode: In-Game Only" >> $LOGFILE; fi
if [ $dbg = 1 ]; then
MODE=9
else
MODE=4
fi
echo "$MODE" > $XBOXMGR
echo "$ABLE" >> $XBOXMGR
ASK_TO_REBOOT=1
}

do_joy_swap() {
if [ "$dbg" = "1" ]; then 
echo "joyswap: do_joy_swap" >> $LOGFILE
echo "joyswap: CONFIGDIR: $CONFIGDIR" >> $LOGFILE
echo "joyswap: XBDRDIR: $XBDRDIR" >> $LOGFILE
echo "joyswap: XBOXMGR: $XBOXMGR" >> $LOGFILE
echo "joyswap: RACONFIGFILE: $RACONFIGFILE" >> $LOGFILE
fi

sed 's@input_player1_joypad_index@input_playerAAA_joypad_index@g' $RACONFIGFILE > $XBDRDIR/.tmpxileh
if [ "$dbg" = "1" ]; then echo "joyswap: do_joy_swap A" >> $LOGFILE; fi
sed 's@input_player2_joypad_index@input_player1_joypad_index@g' $XBDRDIR/.tmpxileh > $XBDRDIR/.tmpxilei
if [ "$dbg" = "1" ]; then echo "joyswap: do_joy_swap B" >> $LOGFILE; fi
sudo cp $CONFIGDIR/retroarch.cfg $CONFIGDIR/retroarch.cfg.bup
sudo sed 's/input_playerAAA_joypad_index/input_player2_joypad_index/g' $XBDRDIR/.tmpxilei > $CONFIGDIR/retroarch.cfg
sudo rm $XBDRDIR/.tmpxileh
sudo rm $XBDRDIR/.tmpxilei
if [ "$dbg" = "1" ]; then echo "joyswap: do_joy_swap END!" >> $LOGFILE; fi
}

do_debug_on(){
case $MODE in
	0)
	MODE=5
	;;
	1)
	MODE=6
	;;
	2)
	MODE=7
	;;
	3)
	MODE=8
	;;
	4)
	MODE=9
	;;
	5)
	MODE=5
	;;
	6)
	MODE=6
	;;
	7)
	MODE=7
	;;
	8)
	MODE=8
	;;
	9)
	MODE=9
	;;
	*)
	MODE=5
esac
dbg = 1
if [ "$dbg" = "1" ]; then echo "joyswap: debug mode: on" >> $LOGFILE; fi
echo "$MODE" > $XBOXMGR
echo "$ABLE" >> $XBOXMGR
}

do_debug_off(){
case $MODE in
	0)
	MODE=0
	;;
	1)
	MODE=1
	;;
	2)
	MODE=2
	;;
	3)
	MODE=3
	;;
	4)
	MODE=4
	;;
	5)
	MODE=0
	;;
	6)
	MODE=1
	;;
	7)
	MODE=2
	;;
	8)
	MODE=3
	;;
	9)
	MODE=4
	;;
	*)
	MODE=0
esac
if [ "$dbg" = "1" ]; then echo "joyswap: debug mode: off" >> $LOGFILE; fi
dbg = 0
echo "$MODE" > $XBOXMGR
echo "$ABLE" >> $XBOXMGR
}

do_init(){
$XBDRDIR/rcfix.sh
ASK_TO_REBOOT=1
}

#
# Interactive use loop
#
calc_wt_size
while true; do
  FUN=$(whiptail --title "Raspberry Pi Xboxdrv-helper" --menu "Setup Options" $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT --cancel-button Finish --ok-button Select \
    "1 Disable" "Don't parse config scripts" \
    "2 Automatic (config-file) Mode" "Uses default config" \
    "3 NON Daemon Mode" "Non-Daemon config file" \
    "4 Forced Daemon Mode" "Forced Daemon mode" \
    "5 Enable Only in Game" "Only use Xboxdrv in-game" \
    "6 Swap Joystick 0 and 1" "" \
    "7 Enable Debug" "Logs to $CONFIGDIR/xboxdrv/xdrv.log" \
    "8 Disable Debug" "Disable logging" \
    "9 About Xboxdrv-helper" " " \
    "10 Initialize Joyhelp" "Generate config files for xboxdrv" \
    3>&1 1>&2 2>&3)
  RET=$?
  if [ $RET -eq 1 ]; then
    do_finish
  elif [ $RET -eq 0 ]; then
    case "$FUN" in
      1\ *) do_mode_disable ;;
      2\ *) do_mode_auto ;;
      3\ *) do_mode_nodaemon ;;
      4\ *) do_mode_daemon ;;
      5\ *) do_mode_ingameonly ;;
      6\ *) do_joy_swap ;;
      7\ *) do_debug_on ;;
      8\ *) do_debug_off ;;
      9\ *) do_about ;;
	  10\ *) do_init ;;
      *) whiptail --msgbox "Programmer error: unrecognized option" 20 60 1 ;;
    esac || whiptail --msgbox "There was an error running option $FUN" 20 60 1
  else
    exit 1
  fi
done
