#!/bin/bash

#######JOYHELP-RCFIX########
###### by SoMuchCode #######
############################
# 
# rchelp.sh
# This file is meant to be run from rc.local at boot time...
# It detects changes to the joyhelp.cfg file and if it has changed, rchelp.sh calls configfix.sh and generates new config files for joyhelp to use
# This file also loads modules for xboxdrv and xpad support based on config file.
# If we are in xboxdrv daemon mode (3), joyhelp-daemon.cfg will be used, otherwise joyhelp-nodaemon.cfg is the default.
# When a game is launched a different script (runcommand) checks configs and determines how to load the drivers

# JOYHELP DIRECTORIES
# maybe these could change...
# important files and directories
CONFIGDIR=/opt/retropie/configs/all
JOYHELPDIR=$CONFIGDIR/joyhelp
DEFCFG=$JOYHELPDIR/joyhelp.cfg		# this is the control config file...
logfile=$JOYHELPDIR/joyhelp.log


#################

# System specific variables
# used by runcommand-onstart
declare -i xpad=1
declare -i xboxdrv=0
declare -i loadcalibrationfile=0
declare -i xbdctrlr=4
calfilelocation=""
p1_profile=""
p2_profile=""
p3_profile=""
p4_profile=""
declare -i arcaderomlists=0
arcaderom4way="--four-way-restrictor"
arcaderomdial="--four-way-restrictor"
arcaderomtrackball=""
arcaderomanalog=""

# RetroPie specific variables
# used by runcommand-onend and rc.local
declare -i xpadrp=1
declare -i xboxdrvrp=0
declare -i debug=0
declare -i loadcalibrationfilerp=0
calfilelocationrp=""
declare -i sudoForced=0
# Global variables
DEFCONTENT=""
CFGCONTENT=""
xpadloaded=""
xboxdrvloaded=""
configchanged=""

if [ -f "$JOYHELPDIR/joyhelp-config.cfg" ] && [ -f "$JOYHELPDIR/joyhelp-config.old" ]; then
	configchanged=$( diff $JOYHELPDIR/joyhelp-config.cfg $JOYHELPDIR/joyhelp-config.old )
fi

if [ ! -f "$JOYHELPDIR/joyhelp-config.old" ]; then
	configchanged="yup"
fi

### Kill Commands
xboxkill="sudo killall xboxdrv > /dev/null 2>&1"
xpadkill="sudo rmmod xpad > /dev/null 2>&1"
xpadstart="sudo modprobe xpad dpad_to_buttons=1 triggers_to_buttons=1 > /dev/null 2>&1"
xpadrestart="sudo modprobe -r xpad && sudo modprobe xpad dpad_to_buttons=1 triggers_to_buttons=1 > /dev/null 2>&1"

do_read_config() {
# Read default RetroPie Joyhelp (GUI) config file...

if [ -f "$DEFCFG" ]
then
  DEFCONTENT=$(cat $DEFCFG | sed -r '/[^=]+=[^=]+/!d' | sed -r 's/\s+=\s/=/g')
  eval "$DEFCONTENT"
  #echo "$DEFCONTENT"
else
	echo "Main config file not found: $DEFCFG"
	exit 1
fi

## Sort out some variables

## JS Calibration file
# This JS cal file is loaded when RetroPie boots
if [ "$calfilelocationrp" ]; then
	xtemp=$calfilelocationrp
	calfilelocation="$xtemp > /dev/null 2>&1"
fi

if [ "$debug" -ge "1" ]; then echo "rchelp: running - $(date)" >> $logfile; fi

}
do_drivers_loaded() {
	xpadloaded=$( lsmod | grep xpad )
	xboxdrvloaded=$( ps -A | grep xboxdrv )
}

do_read_config
do_drivers_loaded

# if the joyhelp-config.cfg changed then we will run configfix to generate new config files.
if [ "$configchanged" != "" ]; then
	#exec $JOYHELPDIR/configfix.sh
	$JOYHELPDIR/configfix.sh
fi

# Kill drivers that we don't want loaded
if [ "$xpadrp" = "0" ] && [ "$xpadloaded" ]; then
	$xpadkill
fi
if [ "$xboxdrvrp" = "0" ] && [ "$xboxdrvloaded" ]; then
	$xboxkill
fi

# we should load these now in case the user is using xboxdrv to remap keys in game
sudo modprobe uinput
sudo modprobe joydev
	
if [ "$xboxdrvrp" = "1" ] || [ "$xboxdrvrp" = "2" ]		# We are NOT in daemon mode, so use no-daemon config file
then
	configfile=$JOYHELPDIR/joyhelp-nodaemon.cfg
	basicXBOX=$(cat "$configfile")
	xcommand="$basicXBOX"
	eval $xcommand
fi

if [ "$xboxdrvrp" = "3" ]		# daemon mode, so use daemon config file
then
	configfile=$JOYHELPDIR/joyhelp-daemon.cfg
	basicXBOX=$(cat "$configfile")
	xcommand="$basicXBOX &"
	eval $xcommand
fi

# these are for the debug log
if [ "$debug" -ge "1" ]; then
	echo "rchelp: $(date)" > $logfile
	echo "rchelp: xpadrp = $xpadrp" >> $logfile
	echo "rchelp: xboxdrvrp = $xboxdrvrp" >> $logfile
	sudo chown pi:pi $logfile
fi

# Run calibration file??
if [ "$loadcalibrationfilerp" = 1 ]; then
	if [ -f "$calfilelocationrp" ]; then
	$calfilelocationrp" > /dev/null 2>&1"
	fi
fi

exit 0
