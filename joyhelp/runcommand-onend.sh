#!/bin/sh

## This does not work in daemon mode.

# /opt/retropie/configs/all/runcommand-onend.sh

# JOYHELP DIRECTORIES
# maybe these could change...
CONFIGDIR=/opt/retropie/configs/all
XBDRDIR=$CONFIGDIR/joyhelp
#XBDRDIR=$CONFIGDIR/x-b-o-x-d-r-v   # so regexp doesn't del this line...

# Don't Change These
XBOXMGR=$XBDRDIR/joyhelp-enable.cfg
RACONFIGFILE=$CONFIGDIR/retroarch.cfg
LOGFILE=$XBDRDIR/xdrv.log

MODE=$(cat "$XBOXMGR" | head -c1)

configfile=$XBDRDIR/joyhelp-config.cfg
basicXBOX=$(cat "$configfile")
daemon=$(cat "$configfile" | grep daemon)
#################

# want more output logged to file?
# change DBG to "1"
DBG="0"
# See if debug is enabled in config file...
if [ "$MODE" = "5" ] || [ "$MODE" = "6" ] || [ "$MODE" = "7" ] || [ "$MODE" = "8" ] || [ "$MODE" = "9" ]
then
	DBG="1"
fi
if [ "$DBG" = "1" ]; then echo "rcoe: running - $(date)" >> $LOGFILE; fi

### Kill Command
#xboxkill="sudo killall >/dev/null xboxdrv"
xboxkill="sudo killall xboxdrv > /dev/null 2>&1"

# Test our modes
# to determine what config file to use
# or if we should just exit now.
if [ "$MODE" = "0" ] || [ "$MODE" = "3" ] || [ "$MODE" = "5" ] || [ "$MODE" = "8" ]		# check if we are even needed
then
	if [ "$DBG" = "1" ]; then echo "rcoe: did nothing - exit 0 - enabled = $MODE" >> $LOGFILE; fi
	exit 0					# not needed, just exit
fi				# we can be in mode 1 or 2 only at this point

if [ "$MODE" = "1" ] || [ "$MODE" = "6" ]		# If yes then we are a go!
then
	if [ "$daemon" != "" ]		# test if we are running as a daemon
	then
		daemon="1"
		if [ "$DBG" = "1" ]; then echo "rcoe: did nothing - daemon - exit 0 - enabled = $MODE" >> $LOGFILE; fi
		exit 0		# xboxdrv running as a daemon, just exit
	else
		daemon="0"	# not a daemon, we can continue
	fi
fi
# Currently no test for modes: 4/9, they are non-daemon modes
if [ "$DBG" = "1" ]; then echo "rcoe: passed tests" >> $LOGFILE; fi
if [ "$DBG" = "1" ]; then echo "rcoe: not a daemon" >> $LOGFILE; fi

# if we made it here, we are NOT a deamon and we are NOT disabled.
# we are in mode 1,2, or 4 or we would have exited by now

# it should be safe to use the 'joyhelp-nodaemon.cfg'
configfile=$XBDRDIR/joyhelp-nodaemon.cfg

# We don't need this anymore...
$xboxkill

if [ "$MODE" = "1" ] || [ "$MODE" = "6" ] || [ "$MODE" = "2" ] || [ "$MODE" = "7" ]			# use default config file
then
	echo "joyhelp-enable.cfg = 1"
	# Load controller config from file.
	basicXBOX=$(cat "$configfile")
	xcommand="$basicXBOX"
	if [ "$DBG" = "1" ]; then echo "rcoe: mode $MODE" >> $LOGFILE; fi
	if [ "$DBG" = "1" ]; then echo "rcoe: $xcommand" >> $LOGFILE; fi
	if [ "$DBG" = "1" ]; then ps -A | grep xboxdrv >> $LOGFILE; fi
	eval $xcommand
fi

if [ "$MODE" = "4" ] || [ "$MODE" = "9" ]		# Enable only in game, don't need a new profile on exit
then
	if [ "$DBG" = "1" ]; then echo "rcoe: Do not re-enable, mode $MODE" >> $LOGFILE; fi
	if [ "$DBG" = "1" ]; then ps -A | grep xboxdrv >> $LOGFILE; fi
	sudo modprobe -r xpad && sudo modprobe xpad dpad_to_buttons=1 triggers_to_buttons=1		# required to reconnect to xpad
fi
