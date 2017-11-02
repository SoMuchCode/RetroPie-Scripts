#!/bin/bash

# When a system has closed, this script kills and loads the controller appropriate drivers
# to retrun us to the default config.

# important files and directories
CONFIGDIR=/opt/retropie/configs/all
JOYHELPDIR=$CONFIGDIR/joyhelp
DEFCFG=$JOYHELPDIR/joyhelp.cfg		# this is the control config file...
logfile=$JOYHELPDIR/joyhelp.log
configfile=$JOYHELPDIR/joyhelp-nodaemon.cfg	# this is the xboxdrv config file
joycommand=$(cat "$configfile")
# set default variables

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
# This JS cal file is loaded when a game is launched
if [ "$calfilelocation" ]; then
	xtemp=$calfilelocation
	calfilelocation="$xtemp > /dev/null 2>&1"
fi

# This JS cal file is loaded RetroPie boots
if [ "$calfilelocationrp" ]; then
	xtemp=$calfilelocationrp
	calfilelocation="$xtemp > /dev/null 2>&1"
fi

if [ "$debug" -ge "1" ]; then echo "rcoe: running - $(date)" >> $logfile; fi
}

do_drivers_loaded() {
	xpadloaded=$( lsmod | grep xpad )
	xboxdrvloaded=$( ps -A | grep xboxdrv )
}

# runcommand-onendstuff
do_read_config
do_drivers_loaded

# Test for xboxdrv daemon mode
if [ "$xboxdrvrp" = 3 ]; then
	# Load calibration file??
	if [ "$loadcalibrationfilerp" = 1 ]; then
		if [ -f "$calfilelocationrp" ]; then
		$calfilelocationrp" > /dev/null 2>&1"
		fi
	fi
	if [ "$xpadloaded" ] && [ "$xpadrp" = 0 ]; then
		# kill xpad driver
		eval $xpadkill
	fi	
	if [ "$xpadloaded" = "" ] && [ "$xpadrp" = 1 ]; then
		# launch xpad driver
		eval $xpadstart
	fi	
	if [ "$debug" -ge "1" ]; then echo "rcoe: Daemon mode - exiting" >> $logfile; fi
	exit 0
fi

# if we made it here, we are NOT a daemon
if [ "$debug" -ge "1" ]; then echo "rcoe: passed tests" >> $logfile; fi
if [ "$debug" -ge "1" ]; then echo "rcoe: not a daemon" >> $logfile; fi

if [ "$debug" -ge "2" ]; then 
echo "rcoe: start: lsmod" >> $logfile
lsmod >> $logfile
fi

eval $xpadkill
if [ "$debug" -ge "1" ]; then echo "rcoe: xpad killed" >> $logfile; fi
eval $xboxkill
if [ "$debug" -ge "1" ]; then echo "rcoe: xboxdrv killed" >> $logfile; fi

if [ "$xpadrp" = 1 ]; then
	# launch xpad driver
	eval $xpadstart
	if [ "$debug" -ge "1" ]; then echo "rcoe: xpad started" >> $logfile; fi
fi	

if [ "$xboxdrvrp" = 1 ] || [ "$xboxdrvrp" = 2 ]; then
	eval $joycommand
	if [ "$debug" -ge "1" ]; then echo "rcoe: $joycommand" >> $logfile; fi
fi

# Load calibration file??
if [ "$loadcalibrationfile" = 1 ]; then
	if [ -f "$calfilelocation" ]; then
	$calfilelocation" > /dev/null 2>&1"
	if [ "$debug" -ge "1" ]; then echo "rcoe: $calfilelocation loaded" >> $logfile; fi
	fi
fi

if [ "$debug" -ge "2" ]; then 
echo "rcoe: end: lsmod" >> $logfile
lsmod >> $logfile
fi

exit 0
