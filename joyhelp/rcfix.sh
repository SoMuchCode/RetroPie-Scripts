#!/bin/bash

#######JOYHELP-RCFIX########
###### by SoMuchCode #######
############################
# rcfix.sh
# script to parse rc.local and create initial config for joyhelp
# uses rcfix.dat

# JOYHELP DIRECTORIES
# maybe these could change...
CONFIGDIR=/opt/retropie/configs/all
JOYHELPDIR=$CONFIGDIR/joyhelp
DEFCFG=$JOYHELPDIR/joyhelp.cfg
RACONFIGFILE=$CONFIGDIR/retroarch.cfg
logfile=$JOYHELPDIR/joyhelp.log

configfile=/etc/rc.local
# configfile=rc.locanew

basicXBOX=$(cat "$configfile")
RCTEMP=$(cat "$configfile")
XBD=$(cat "$configfile" | grep xboxdrv)
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
p1_lconfig=""
p2_lconfig=""
p3_lconfig=""
p4_lconfig=""

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
p1_id=""
p2_id=""
p3_id=""
p4_id=""

do_make_mainconfig() {
echo "# Joyhelp Config

[SYSTEM-GUI]
# These are the settings used when you are in the RetroPie menu, selecting games, etc...
# xpad: 0=disabled, 1=enabled
xpadrp = 1

# xboxdrv: 0=disabled, 1=enabled, 2=reserved, 3=daemon mode
xboxdrvrp = 0

# xboxdrv run as sudo?
sudoForced = 1

# Load jscal format calibration file?
loadcalibrationfilerp = 0

# Joystick calibration file path/name
calfilelocationrp = \"~/jscal.sh\"

# Set logging mode: 0=off, 1=log to file, 2=log to file - really verbose
debug = 0

#Logfile: uncomment to add custom logfile location
logfile = \"/opt/retropie/configs/all/joyhelp/joyhelp.log\"

# Force silent mode, this is recommended otherwise xboxdrv uses more RAM
# and sends data to terminal
silent = 1 
" > $DEFCFG
}

do_make_config() {
echo "[SYSTEM]
# If an unknown system is launched or a new one added, these are the defaults used.
# xpad: 0=disabled, 1=enabled
xpad = 1

# xboxdrv: 0=disabled, 1=enabled
xboxdrv = 0

# how many xboxdrv drivers to spawn. Disabled / default is 4
#xbdctrlr = 2

# Load jscal format calibration file?
loadcalibrationfile = 0

# Joystick calibration file path/name
calfilelocation = \"~/jscal.sh\"

# Custom commands.
#p1_profile = \"--evdev-absmap ABS_X=x1,ABS_Y=y1,ABS_RX=x2,ABS_RY=y2,ABS_HAT0X=dpad_x,ABS_HAT0Y=dpad_y --evdev-keymap BTN_TL2=lt,BTN_TR2=rt --evdev-keymap BTN_SOUTH=a,BTN_EAST=b,BTN_WEST=x,BTN_NORTH=y,BTN_TL=lb,BTN_TR=rb,BTN_THUMBL=tl,BTN_THUMBR=tr,BTN_MODE=guide,BTN_SELECT=back,BTN_START=start\"
p2_profile = \"\"
p3_profile = \"\"
p4_profile = \"\"

#p1_id=\"045e:028e\"
#p2_id=\"0079:0011\"
#p3_id=\"\"
#p4_id=\"\"

#p1_lconfig=\"--id 0 --led 2 --type xbox360 --deadzone 4400\"
#p2_lconfig=\"--id 1 --led 3 --type xbox360 --deadzone 4400\"
#p3_lconfig=\"--id 2 --led 4 --type xbox360 --deadzone 4400\"
#p4_lconfig=\"--id 3 --led 5 --type xbox360 --deadzone 4400\"

# Arcade use rom lists
# These commands will be applied to the every controller
arcaderomlists = 1
arcaderom4way = \"--four-way-restrictor\"
arcaderomdial = \"--four-way-restrictor\"
arcaderomtrackball = \"\"
arcaderomanalog = \"\"

#EOF" >> $DEFCFG
}

do_read_config() {
# Read default RetroPie Joyhelp (GUI) config file...

if [ -f "$DEFCFG" ]
then
  DEFCONTENT=$(cat $DEFCFG | sed -r '/[^=]+=[^=]+/!d' | sed -r 's/\s+=\s/=/g')
  eval "$DEFCONTENT"
else
	do_make_mainconfig
	do_make_config
	if [ -f "$DEFCFG" ]
	then
	  DEFCONTENT=$(cat $DEFCFG | sed -r '/[^=]+=[^=]+/!d' | sed -r 's/\s+=\s/=/g')
	  eval "$DEFCONTENT"
	fi
fi

# This JS cal file is loaded RetroPie boots
if [ "$calfilelocationrp" ]; then
	xtemp=$calfilelocationrp
	calfilelocationrp="$xtemp > /dev/null 2>&1"
fi

if [ "$debug" -ge "1" ]; then echo "rcfix: running - $(date)" >> $logfile; fi

}

do_read_config

defaultConfig="sudo /opt/retropie/supplementary/xboxdrv/bin/xboxdrv --daemon --detach --id 0 --led 2 --type xbox360 --deadzone 4400 --silent --trigger-as-button --alt-config /opt/retropie/configs/all/joyhelp/controller_configs/xboxdrv_4way.cfg --alt-config /opt/retropie/configs/all/joyhelp/controller_configs/xboxdrv_player1.cfg --alt-config /opt/retropie/configs/all/joyhelp/controller_configs/mouse.cfg --next-controller --id 1 --led 3 --type xbox360 --deadzone 4400 --silent --trigger-as-button --alt-config /opt/retropie/configs/all/joyhelp/controller_configs/xboxdrv_4way.cfg --alt-config /opt/retropie/configs/all/joyhelp/controller_configs/xboxdrv_player2.cfg --next-controller --controller-slot 2 --id 2 --led 4 --type xbox360 --deadzone 4400 --silent --trigger-as-button --alt-config /opt/retropie/configs/all/joyhelp/controller_configs/xboxdrv_4way.cfg --next-controller --controller-slot 3 --id 3 --led 5 --type xbox360 --deadzone 4400 --silent --trigger-as-button --alt-config /opt/retropie/configs/all/joyhelp/controller_configs/xboxdrv_4way.cfg --dbus disabled --detach-kernel-driver"

## DO some logging
if [ "$debug" -ge "1" ]; then echo "rcfix: running - $(date)" >> $logfile; fi
if [ "$debug" -ge "1" ]; then echo "rcfix: Original Config:  $(cat $configfile)" >> $logfile; fi

# Create temporary file - 
if [ "$XBD" ]; then			# we only want to do this if we need to...
	PREFIX=$(cat $configfile | grep xboxdrv)
	echo "$PREFIX" > $JOYHELPDIR/.tempdfile1
	cat $JOYHELPDIR/.tempdfile1 | head -n 1 > $JOYHELPDIR/.tempdfile2
	sed 's/\"//g' $JOYHELPDIR/.tempdfile2 > $JOYHELPDIR/.tempdfile3
	sed 's/\\//g' $JOYHELPDIR/.tempdfile3 > $JOYHELPDIR/.tempdfile4
	sed 's/xboxdrv.*/xboxdrv/g' $JOYHELPDIR/.tempdfile4 > $JOYHELPDIR/.launchoutfile		## This is the first line of the launch outfile, it may have sudo in it
	
else
	# if we want to make a default config - here is where we would put it
	# xboxdrv should make one when it is installed
	echo "$defaultConfig" > $JOYHELPDIR/.launchoutfile
	XBD="HELL YEAH"
	
fi
## Now we should have a New rc.local TAIL in .launchoutfile

# New rc.local HEAD
# remove newlines 
echo "$RCTEMP" > $JOYHELPDIR/.tempdfile1
tr -s '\n' ' ' < $JOYHELPDIR/.tempdfile1 > $JOYHELPDIR/.tempdfile2
tr -s '\r' ' ' < $JOYHELPDIR/.tempdfile2 > $JOYHELPDIR/.tempdfile3
sed 's/\"/ /g' $JOYHELPDIR/.tempdfile3 > $JOYHELPDIR/.tempdfile4
sed 's/\\/\\ /g' $JOYHELPDIR/.tempdfile4 > $JOYHELPDIR/.tempdfile3
sed 's/  / /g' $JOYHELPDIR/.tempdfile3 > $JOYHELPDIR/.tempdfile2

RCTEMP=$(cat "$JOYHELPDIR/.tempdfile2")			## RE_DEFINED RCTEMP!!!!
foundit=0			## Flow control
outfile=""			## The outfile we are working on
for word in $RCTEMP
	do
		case $word in			# we don't want the outfile in our player files...
			*boxdr*)
			if [ "$foundit" = 0 ]; then 
				foundit=1
				word=""
			fi
			;;
			xboxdrv)
			if [ "$foundit" = 0 ]; then 
				foundit=1
				word=""
			fi
			;;
			xboxdrv)
			if [ "$foundit" = 0 ]; then 
				foundit=1
				word=""
			fi
			;;
			esac
	
		if [ "$foundit" = 0 ]; then
			word=""
		fi
		
		if [ "$foundit" = 1 ] && [ "$word" = "exit" ]; then
			word=""
			foundit=0
		fi
		
		if [ "$word" != "" ]; then
			outfile=$outfile" "$word
		fi
	done
	
echo "$outfile" >> $JOYHELPDIR/.launchoutfile
tr -s '\n' ' ' < $JOYHELPDIR/.launchoutfile > $JOYHELPDIR/.tempdfile1
tr -s '\r' ' ' < $JOYHELPDIR/.tempdfile1 > $JOYHELPDIR/.tempdfile2
sed 's|\\|\\ \n|g' $JOYHELPDIR/.tempdfile2 > $JOYHELPDIR/.tempdfile3
sed 's|&|& \n|g' $JOYHELPDIR/.tempdfile3 > $JOYHELPDIR/.tempdfile4
sed 's|#||g' $JOYHELPDIR/.tempdfile4 > $JOYHELPDIR/.tempdfile2
sed 's|sleep 1|sleep 1 \n|g' $JOYHELPDIR/.tempdfile2 > $JOYHELPDIR/.tempdfile3
sed 's|sleep 2|sleep 2 \n|g' $JOYHELPDIR/.tempdfile3 > $JOYHELPDIR/.launchoutfile

## We should have a fairly sane config file now, no matter the style
cat "$JOYHELPDIR/.launchoutfile" > joyhelp-config.cfg

### NEXT SEXTION
#
## See if we have already been installed
# read rc.local again
RCTEMP=$(cat "$configfile")
JOYHELP=$(cat "$configfile" | grep joyhelp)
if [ "$JOYHELP" = "" ]; then
	JOYHELP=$(cat "$configfile" | grep JOYHELP)
fi
# Define some variables
found="no"
outfile=""			## The outfile we are working on

# make the file one line and replace newline with unique pattern
echo "$RCTEMP" > $JOYHELPDIR/.tempdfile1			## grab rc.local that is flat and should be split at word: xboxdrv
tr -s '\r' ' ' < $JOYHELPDIR/.tempdfile1 > $JOYHELPDIR/.tempdfile2
sed ':a;N;$!ba;s|\n| jjjjjCLMjjjjj |g' $JOYHELPDIR/.tempdfile2 > $JOYHELPDIR/.tempdfile3

RCTEMP=$(cat "$JOYHELPDIR/.tempdfile3")		# This is the original (full) flartened/custom delimited rc.local
delim="#######JOYHELP-CONFIG#######"
delimb="sudo"
for word in $RCTEMP
	do
		case $word in			# we don't want the outfile in our player files...
			xboxdrv*)
			found="yes"
			;;
			xboxdrv)
			found="yes"
			;;
			*boxdrv*)
			found="yes"
			;;
			"$delim")
			found="yes"
			;;
			"$delimb")		### This is ugly, but i don't know how else to get rid of an errant sudo
			word=""
			;;
			"JOYHELP")
			found="yes"
			;;
		esac

		#echo "$found"
		
		if [ "$found" = "no" ]; then 
		outfile=$outfile" "$word
		#echo "$word"
		fi
	done
echo "$outfile" > $JOYHELPDIR/.tempdfile1
sed 's|jjjjjCLMjjjjj exit 0|\n|g' $JOYHELPDIR/.tempdfile1 > $JOYHELPDIR/.tempdfile2
sed 's|jjjjjCLMjjjjj |\n|g' $JOYHELPDIR/.tempdfile2 > $JOYHELPDIR/.tempdfile3
sed 's|jjjjjCLMjjjjj|\n|g' $JOYHELPDIR/.tempdfile3 > $JOYHELPDIR/.tempdfile4

## works but kills too much whitespace
# CTEMP=$(cat -s "$JOYHELPDIR/.tempdfile4")
# echo "$CTEMP" > $JOYHELPDIR/.tempdfile2

# wow, sed can remove \n\n
sed 'N;/^\n$/D;P;D;' $JOYHELPDIR/.tempdfile4 > $JOYHELPDIR/.tempdfile2

sed 's|  | |g' $JOYHELPDIR/.tempdfile2 > $JOYHELPDIR/.tempdfile1
sed 's| #!/bin/sh|#!/bin/sh|g' $JOYHELPDIR/.tempdfile1 > $JOYHELPDIR/.rc-head

if [ "$JOYHELP" = "" ]; then			## hey we are NOT installed
	sudo cp $configfile "$configfile".bakup
	XXD=$(cat "$JOYHELPDIR/.scripts/rcfix.dat")
	if [ "$debug" -ge "1" ]; then echo "rcfix: Joyhelp not installed in rc.local; Install it now!" >> $logfile; fi
	echo "$XXD"	>> $JOYHELPDIR/.rc-head
else									## We are installed, do an in-place update of script in rc.local
	XXD=$(cat "$JOYHELPDIR/.scripts/rcfix.dat")		## we should flag this somewhere so we can do a full update
	echo "$XXD"	>> $JOYHELPDIR/.rc-head	## if needed...
	if [ "$debug" -ge "1" ]; then echo "rcfix: Joyhelp already installed in rc.local; Update it now!" >> $logfile; fi
	#####echo "updated"	>> $JOYHELPDIR/.rclocal-updated		## IDK what to do with this, but now it's flagged
fi
	echo "" > $JOYHELPDIR/.tempdfile2
	tr -s '\r' ' ' < $JOYHELPDIR/.launchoutfile >> $JOYHELPDIR/.tempdfile2
	sed ':a;N;$!ba;s|\n|jjjjjCLMjjjjj|g' $JOYHELPDIR/.tempdfile2 > $JOYHELPDIR/.tempdfile3	
	sed 's|jjjjjCLMjjjjj|\n#|g' $JOYHELPDIR/.tempdfile3 >> $JOYHELPDIR/.rc-head


# make sure we have an exit 0 at the end of new rc.local
exitOK=$(cat "$JOYHELPDIR/.rc-head" | grep "exit 0")
if [ "$exitOK" != "" ]; then
	echo "" >> $JOYHELPDIR/.rc-head
	echo "exit 0" >> $JOYHELPDIR/.rc-head
fi

sudo cp $JOYHELPDIR/.rc-head "$configfile"

sudo rm $JOYHELPDIR/.launchoutfile
sudo rm $JOYHELPDIR/.tempdfile4
sudo rm $JOYHELPDIR/.tempdfile3
sudo rm $JOYHELPDIR/.tempdfile2
sudo rm $JOYHELPDIR/.tempdfile1
sudo rm $JOYHELPDIR/.rc-head

#######################################

if [ "$debug" -ge "1" ]; then echo "rcfix: running - $(date)" >> $logfile; fi
if [ "$debug" -ge "1" ]; then echo "rcfix: Original Config:  $(cat $configfile)" >> $logfile; fi

## Now that we have fixed (hopefully) rc.local,
## we can make the config files...
$JOYHELPDIR/configfix.sh

# since we have just initialized the system we can remove our old config this way new ones are guaranteed to be generated.
if [ -f "$JOYHELPDIR/joyhelp-config.old" ]; then
	sudo rm $JOYHELPDIR/joyhelp-config.old
fi

# Made it to the end
exit 0