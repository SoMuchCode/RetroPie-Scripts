#!/bin/bash 

########JOYHELP-MENU########
# ~/RetroPie/retropiemenu/joyhelp.sh

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
SYSCONFIGDIR=/opt/retropie/configs
CONFIGDIR=/opt/retropie/configs/all
JOYHELPDIR=$CONFIGDIR/joyhelp

# Don't Change These
DEFCFG=$JOYHELPDIR/joyhelp.cfg
RACONFIGFILE=$CONFIGDIR/retroarch.cfg		# Used for joyswap
logfile=$JOYHELPDIR/joyhelp.log
CFGOUTFILE=$JOYHELPDIR/.joyhelp.cfg
SYSCFGOUTFILE=$JOYHELPDIR/.joyhelp.cfg		# this can change if we only want to write system config

INTERACTIVE=True
ASK_TO_REBOOT=0
WT_WIDTH=80
WT_WIDTH=120
WT_MENU_HEIGHT=$(($WT_HEIGHT-7))

system="Not_Selected"
controllerID=""
controllerName=""
playerNum="Disabled"
mimic="Disabled"
type="Disabled"

# System specific variables
# used by runcommand-onstart
declare -i xpad=1
declare -i xboxdrv=0
declare -i loadcalibrationfile=0
declare -i xbdctrlr=4
calfilelocation="~/jscal.sh"
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
calfilelocationrp="~/jscal.sh"
declare -i sudoForced=1
# Global variables
DEFCONTENT=""
CFGCONTENT=""
xpadloaded=""
xboxdrvloaded=""
p1_id=""
p2_id=""
p3_id=""
p4_id=""
p1_bid=""
p2_bid=""
p3_bid=""
p4_bid=""

debug=0
needtoinit=0
configchanged=0
systemfullpath=""		# global used when editing a system specific config file.
sysconfigchanged=0

do_read_mainconfig() {
# Read default RetroPie Joyhelp (GUI) config file...

if [ -f "$DEFCFG" ]
then
  DEFCONTENT=$(cat $DEFCFG | sed -r '/[^=]+=[^=]+/!d' | sed -r 's/\s+=\s/=/g')
  eval "$DEFCONTENT"
else
	do_please_init
fi

## Sort out some variables
## JS Calibration file
# This JS cal file is loaded when a game is launched
if [ "$calfilelocation" ]; then
	xtemp=$calfilelocation
	calfilelocation="$xtemp"
fi

# This JS cal file is loaded RetroPie boots
if [ "$calfilelocationrp" ]; then
	xtemp=$calfilelocationrp
	calfilelocationrp="$xtemp"
fi
if [ "$debug" -ge "1" ]; then echo "joyhelp: running - $(date)" >> $logfile; fi
}

do_drivers_loaded() {
	xpadloaded=$( lsmod | grep xpad )
	xboxdrvloaded=$( ps -A | grep xboxdrv )
}

do_write_mainconfig() {
echo "# Joyhelp Config" > $CFGOUTFILE
echo "" >> $CFGOUTFILE
echo "[SYSTEM-GUI]" >> $CFGOUTFILE
echo "# These are the settings used when you are in the RetroPie menu, selecting games, etc..." >> $CFGOUTFILE
echo "# xpad: 0=disabled, 1=enabled" >> $CFGOUTFILE
echo "xpadrp = $xpadrp" >> $CFGOUTFILE
echo "" >> $CFGOUTFILE
echo "# xboxdrv: 0=disabled, 1=enabled, 2=reserved, 3=daemon mode" >> $CFGOUTFILE
echo "xboxdrvrp = $xboxdrvrp" >> $CFGOUTFILE
echo "" >> $CFGOUTFILE
echo "# xboxdrv run as sudo?" >> $CFGOUTFILE
echo "sudoForced = $sudoForced" >> $CFGOUTFILE
echo "" >> $CFGOUTFILE
echo "# Load jscal format calibration file?" >> $CFGOUTFILE
echo "loadcalibrationfilerp = $loadcalibrationfilerp" >> $CFGOUTFILE
echo "" >> $CFGOUTFILE
echo "# Joystick calibration file path/name" >> $CFGOUTFILE
echo "calfilelocationrp = \"$calfilelocationrp\"" >> $CFGOUTFILE
echo "" >> $CFGOUTFILE
echo "# Set logging mode: 0=off, 1=log to file, 2=log to file - really verbose" >> $CFGOUTFILE
echo "debug = $debug" >> $CFGOUTFILE
echo "" >> $CFGOUTFILE
echo "#logfile: uncomment to add custom logfile location" >> $CFGOUTFILE
echo "#logfile = \"$logfile\"" >> $CFGOUTFILE
echo "" >> $CFGOUTFILE
echo "# Force silent mode, this is recommended otherwise xboxdrv uses more RAM and sends data to terminal" >> $CFGOUTFILE
echo "silent = $silent" >> $CFGOUTFILE
echo "" >> $CFGOUTFILE
}

do_write_sysconfig() {
if [ "$CFGOUTFILE" = "$SYSCFGOUTFILE" ]; then
	echo "[SYSTEM]" >> $SYSCFGOUTFILE
else
	echo "[SYSTEM]" > $SYSCFGOUTFILE
fi
echo "# If an unknown system is launched or a new one added, these are the defaults used." >> $SYSCFGOUTFILE
echo "# xpad: 0=disabled, 1=enabled" >> $SYSCFGOUTFILE
echo "xpad = $xpad" >> $SYSCFGOUTFILE
echo "" >> $SYSCFGOUTFILE
echo "# xboxdrv: 0=disabled, 1=enabled" >> $SYSCFGOUTFILE
echo "xboxdrv = $xboxdrv" >> $SYSCFGOUTFILE
echo "" >> $SYSCFGOUTFILE
echo "# how many xboxdrv drivers to spawn." >> $SYSCFGOUTFILE
echo "#xbdctrlr = 2" >> $SYSCFGOUTFILE
echo "" >> $SYSCFGOUTFILE
echo "# Load jscal format calibration file?" >> $SYSCFGOUTFILE
echo "loadcalibrationfile = $loadcalibrationfile" >> $SYSCFGOUTFILE
echo "" >> $SYSCFGOUTFILE
echo "# Joystick calibration file path/name" >> $SYSCFGOUTFILE
echo "calfilelocation = \"$calfilelocation\"" >> $SYSCFGOUTFILE
echo "" >> $SYSCFGOUTFILE
echo "# Custom commands." >> $SYSCFGOUTFILE

if [ "$p1_profile" ]; then
	echo "p1_profile = \"$p1_profile\"" >> $SYSCFGOUTFILE
else
	echo "#p1_profile = \"$p1_profile\"" >> $SYSCFGOUTFILE
fi
if [ "$p2_profile" ]; then
	echo "p2_profile = \"$p2_profile\"" >> $SYSCFGOUTFILE
else
	echo "#p2_profile = \"$p2_profile\"" >> $SYSCFGOUTFILE
fi
if [ "$p3_profile" ]; then
	echo "p3_profile = \"$p3_profile\"" >> $SYSCFGOUTFILE
else
	echo "#p3_profile = \"$p3_profile\"" >> $SYSCFGOUTFILE
fi
if [ "$p4_profile" ]; then
	echo "p4_profile = \"$p4_profile\"" >> $SYSCFGOUTFILE
else
	echo "#p4_profile = \"$p4_profile\"" >> $SYSCFGOUTFILE
fi

echo "" >> $SYSCFGOUTFILE
if [ "$p1_bid" ]; then
	echo "p1_bid = \"$p1_bid\"" >> $SYSCFGOUTFILE
else
	echo "#p1_bid = \"$p1_bid\"" >> $SYSCFGOUTFILE
fi
if [ "$p2_bid" ]; then
	echo "p2_bid = \"$p2_bid\"" >> $SYSCFGOUTFILE
else
	echo "#p2_bid = \"$p2_bid\"" >> $SYSCFGOUTFILE
fi
if [ "$p3_bid" ]; then
	echo "p3_bid = \"$p3_bid\"" >> $SYSCFGOUTFILE
else
	echo "#p3_bid = \"$p3_bid\"" >> $SYSCFGOUTFILE
fi
if [ "$p4_bid" ]; then
	echo "p4_bid = \"$p4_bid\"" >> $SYSCFGOUTFILE
else
	echo "#p4_bid = \"$p4_bid\"" >> $SYSCFGOUTFILE
fi
echo "" >> $SYSCFGOUTFILE

if [ "$p1_id" ]; then
	echo "p1_id = \"$p1_id\"" >> $SYSCFGOUTFILE
else
	echo "#p1_id = \"$p1_id\"" >> $SYSCFGOUTFILE
fi
if [ "$p2_id" ]; then
	echo "p2_id = \"$p2_id\"" >> $SYSCFGOUTFILE
else
	echo "#p2_id = \"$p2_id\"" >> $SYSCFGOUTFILE
fi
if [ "$p3_id" ]; then
	echo "p3_id = \"$p3_id\"" >> $SYSCFGOUTFILE
else
	echo "#p3_id = \"$p3_id\"" >> $SYSCFGOUTFILE
fi
if [ "$p4_id" ]; then
	echo "p4_id = \"$p4_id\"" >> $SYSCFGOUTFILE
else
	echo "#p4_id = \"$p4_id\"" >> $SYSCFGOUTFILE
fi
echo "" >> $SYSCFGOUTFILE
if [ "$p1_lconfig" ]; then
	echo "p1_lconfig=\"$p1_lconfig\"" >> $SYSCFGOUTFILE
else
	echo "#p1_lconfig=\"$p1_lconfig\"" >> $SYSCFGOUTFILE
fi
if [ "$p2_lconfig" ]; then
	echo "p2_lconfig=\"$p2_lconfig\"" >> $SYSCFGOUTFILE
else
	echo "#p2_lconfig=\"$p2_lconfig\"" >> $SYSCFGOUTFILE
fi
if [ "$p3_lconfig" ]; then
	echo "p3_lconfig=\"$p3_lconfig\"" >> $SYSCFGOUTFILE
else
	echo "#p3_lconfig=\"$p3_lconfig\"" >> $SYSCFGOUTFILE
fi
if [ "$p4_lconfig" ]; then
	echo "p4_lconfig=\"$p4_lconfig\"" >> $SYSCFGOUTFILE
else
	echo "#p4_lconfig=\"$p4_lconfig\"" >> $SYSCFGOUTFILE
fi
echo "" >> $SYSCFGOUTFILE
echo "# Arcade use rom lists" >> $SYSCFGOUTFILE
echo "# These commands will be applied to the every controller" >> $SYSCFGOUTFILE
echo "arcaderomlists = $arcaderomlists" >> $SYSCFGOUTFILE
echo "arcaderom4way = \"--four-way-restrictor\"" >> $SYSCFGOUTFILE
echo "arcaderomdial = \"--four-way-restrictor\"" >> $SYSCFGOUTFILE
echo "arcaderomtrackball = \"\"" >> $SYSCFGOUTFILE
echo "arcaderomanalog = \"\"" >> $SYSCFGOUTFILE
echo "" >> $SYSCFGOUTFILE
echo "#EOF" >> $SYSCFGOUTFILE
if [ "$CFGOUTFILE" = "$SYSCFGOUTFILE" ]; then
	cp $SYSCFGOUTFILE $DEFCFG
else
	echo "### STUB ###"
	echo "write system specific config file... need system name / dir"
fi
}

#systemlist=""
# runcommand-onstart stuff
do_read_mainconfig
#do_drivers_loaded

if [ "$debug" = "1" ]; then echo "joyhelp: running - $(date)" >> $logfile; fi

if [ -f "/etc/rc.local" ]; then
	areweinstalled=$(cat "/etc/rc.local" | grep joyhelp)
	if [ "$areweinstalled" = "" ]; then areweinstalled=$(cat "/etc/rc.local" | grep JOYHELP); fi
fi
if [ "$areweinstalled" = "" ]; then needtoinit=1; fi

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

do_please_init() {
	if (whiptail --title "Joyhelp" --yesno "You need to initialize Joyhelp before you can use it properly. Would you like to initialize is now?" 8 78) then
		do_init
	else
		needtoinit=1
	fi
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
if [ "$configchanged" = "1" ]; then
	whiptail --yesno "Would you like to save config changes?" 20 60 2
    if [ $? -eq 0 ]; then # yes
      SYSCFGOUTFILE=$JOYHELPDIR/.joyhelp.cfg
	  do_write_mainconfig
	  do_write_sysconfig
	  configchanged=0
    fi
fi
  if [ "$ASK_TO_REBOOT" = "1" ]; then
    whiptail --yesno "Would you like to reboot now? you really should if you made any changes or things can get weird." 20 60 2
    if [ $? -eq 0 ]; then # yes
      sync
      reboot
    fi
  fi
  sync
  exit 0
}

do_saveconfig_now() {
if [ "$configchanged" = "1" ]; then
	whiptail --yesno "Would you like to save config changes?" 20 60 2
    if [ $? -eq 0 ]; then # yes
      SYSCFGOUTFILE=$JOYHELPDIR/.joyhelp.cfg
	  do_write_mainconfig
	  do_write_sysconfig
	  configchanged=0
    fi
fi
}

do_xboxdrv_toggle() {
if [ -f "$DEFCFG" ]; then
	case $xboxdrvrp in
	0)
		xboxdrvrp=1
	;;
	1)
		xboxdrvrp=2
	;;
	2)
		xboxdrvrp=3
	;;
	*)
		xboxdrvrp=0
	esac
	if [ "$debug" -ge "1" ]; then echo "joyhelp: xboxdrvrp $xboxdrvrp" >> $logfile; fi
else
	do_please_init
fi
configchanged=1
ASK_TO_REBOOT=1
}

do_xboxdrv_sudo() {
if [ -f "$DEFCFG" ]; then
	case $sudoForced in
	0)
		sudoForced=1
	;;
	*)
		sudoForced=0
	esac
	if [ "$debug" -ge "1" ]; then echo "joyhelp: xboxdrv sudo = $sudoForced" >> $logfile; fi
else
	do_please_init
fi
configchanged=1
ASK_TO_REBOOT=1
}

do_xpad_toggle() {
if [ -f "$DEFCFG" ]; then
	case $xpadrp in
	0)
		xpadrp=1
	;;
	*)
		xpadrp=0
	esac
	if [ "$debug" -ge "1" ]; then echo "joyhelp: xpadrp $xpadrp" >> $logfile; fi
else
	do_please_init
fi
configchanged=1
ASK_TO_REBOOT=1
}

do_joy_swap() {
if [ "$debug" = "1" ]; then 
echo "joyhelp: do_joy_swap" >> $logfile
echo "joyhelp: CONFIGDIR: $CONFIGDIR" >> $logfile
echo "joyhelp: JOYHELPDIR: $JOYHELPDIR" >> $logfile
echo "joyhelp: DEFCFG: $DEFCFG" >> $logfile
echo "joyhelp: RACONFIGFILE: $RACONFIGFILE" >> $logfile
fi

sed 's@input_player1_joypad_index@input_playerAAA_joypad_index@g' $RACONFIGFILE > $JOYHELPDIR/.tmpxileh
if [ "$debug" = "1" ]; then echo "joyhelp: do_joy_swap A" >> $logfile; fi
sed 's@input_player2_joypad_index@input_player1_joypad_index@g' $JOYHELPDIR/.tmpxileh > $JOYHELPDIR/.tmpxilei
if [ "$debug" = "1" ]; then echo "joyhelp: do_joy_swap B" >> $logfile; fi
sudo cp $CONFIGDIR/retroarch.cfg $CONFIGDIR/retroarch.cfg.bup
sudo sed 's/input_playerAAA_joypad_index/input_player2_joypad_index/g' $JOYHELPDIR/.tmpxilei > $CONFIGDIR/retroarch.cfg
sudo rm $JOYHELPDIR/.tmpxileh
sudo rm $JOYHELPDIR/.tmpxilei
if [ "$debug" = "1" ]; then echo "joyhelp: do_joy_swap END!" >> $logfile; fi
}

do_xboxdrvg_toggle() {
if [ -f "$DEFCFG" ]; then
	case $xboxdrv in
	0)
		xboxdrv=1
	;;
	*)
		xboxdrv=0
	esac
	if [ "$debug" -ge "1" ]; then echo "joyhelp: xboxdrv $xboxdrv" >> $logfile; fi
else
	do_please_init
fi
configchanged=1
}

do_xpadg_toggle() {
if [ -f "$DEFCFG" ]; then
	case $xpad in
	0)
		xpad=1
	;;
	*)
		xpad=0
	esac
	if [ "$debug" -ge "1" ]; then echo "joyhelp: xpad $xpad" >> $logfile; fi
else
	do_please_init
fi
configchanged=1
}

do_savesysconfig_now() {
if [ "$sysconfigchanged" = 1 ]; then
	whiptail --yesno "Would you like to save config changes?" 20 60 2
    if [ $? -eq 0 ]; then # yes
      SYSCFGOUTFILE=$systemfullpath
	  do_write_sysconfig
	  sync
	  #exit 0
    fi
fi
	sysconfigchanged=0
	system="Not_Selected"
	SYSCFGOUTFILE=$JOYHELPDIR/.joyhelp.cfg
	do_read_mainconfig
}

do_xboxdrvs_toggle() {
if [ -f "$DEFCFG" ]; then
	case $xboxdrv in
	0)
		xboxdrv=1
	;;
	*)
		xboxdrv=0
	esac
	if [ "$debug" -ge "1" ]; then echo "joyhelp: xboxdrv $xboxdrv" >> $logfile; fi
else
	do_please_init
fi
sysconfigchanged=1
}

do_xpads_toggle() {
if [ -f "$DEFCFG" ]; then
	case $xpad in
	0)
		xpad=1
	;;
	*)
		xpad=0
	esac
	if [ "$debug" -ge "1" ]; then echo "joyhelp: xpad $xpad" >> $logfile; fi
else
	do_please_init
fi
sysconfigchanged=1
}

arc_romlist_toggle() {
if [ -f "$DEFCFG" ]
then
	if [ "$arcaderomlists" = "0" ]; then 
		arcaderomlists=1
	else
		arcaderomlists=0
	fi
else
	do_please_init
fi
sysconfigchanged=1
echo "joyhelp: debug mode: $debug" >> $logfile
}

do_p1_profile() {
	whiptail --title "Joyhelp" --infobox "Not yet implemented." 8 78
	sleep 2
	sysconfigchanged=1
}

do_p2_profile() {
	whiptail --title "Joyhelp" --infobox "Not yet implemented." 8 78
	sleep 2
	sysconfigchanged=1
}

do_p3_profile() {
	whiptail --title "Joyhelp" --infobox "Not yet implemented." 8 78
	sleep 2
	sysconfigchanged=1
}

do_p4_profile() {
	whiptail --title "Joyhelp" --infobox "Not yet implemented." 8 78
	sleep 2
	sysconfigchanged=1
}

arc_dial() {
	whiptail --title "Joyhelp" --infobox "Not yet implemented." 8 78
	sleep 2
	sysconfigchanged=1
}

arc_trackball() {
	whiptail --title "Joyhelp" --infobox "Not yet implemented." 8 78
	sleep 2
	sysconfigchanged=1
}

arc_analog() {
	whiptail --title "Joyhelp" --infobox "Not yet implemented." 8 78
	sleep 2
	sysconfigchanged=1
}

do_debug_toggle() {
if [ -f "$DEFCFG" ]
then
	if [ "$debug" = "0" ]; then 
		debug=1
	else
		debug=0
	fi
else
	do_please_init
fi
configchanged=1
echo "joyhelp: debug mode: $debug" >> $logfile
}

do_init() {
	# make backups
	if [ ! -f "$CONFIGDIR/runcommand-onstart.sh.bakup" ]; then
		if [ -f "$CONFIGDIR/runcommand-onstart.sh" ]; then
			cp "$CONFIGDIR/runcommand-onstart.sh" "$CONFIGDIR/runcommand-onstart.sh.bakup"
		else
			echo "#!/bin/bash" > $CONFIGDIR/runcommand-onstart.sh.bakup
			echo "" >> $CONFIGDIR/runcommand-onstart.sh.bakup
			echo "exit 0" >> $CONFIGDIR/runcommand-onstart.sh.bakup
			chmod +x $CONFIGDIR/runcommand-onstart.sh.bakup
		fi		
	fi
	if [ ! -f "$CONFIGDIR/runcommand-onend.sh.bakup" ]; then
		if [ -f "$CONFIGDIR/runcommand-onend.sh" ]; then
			cp "$CONFIGDIR/runcommand-onend.sh" "$CONFIGDIR/runcommand-onend.sh.bakup"
		else
			echo "#!/bin/bash" > $CONFIGDIR/runcommand-onend.sh.bakup
			echo "" >> $CONFIGDIR/runcommand-onend.sh.bakup
			echo "exit 0" >> $CONFIGDIR/runcommand-onend.sh.bakup
			chmod +x $CONFIGDIR/runcommand-onend.sh.bakup
		fi	
	fi
	# Copy files
	if [ -f "$JOYHELPDIR/.scripts/runcommand-onstart.sh" ]; then
		cp "$JOYHELPDIR/.scripts/runcommand-onstart.sh" "$CONFIGDIR/runcommand-onstart.sh"
	fi
	if [ -f "$JOYHELPDIR/.scripts/runcommand-onend.sh" ]; then
		cp "$JOYHELPDIR/.scripts/runcommand-onend.sh" "$CONFIGDIR/runcommand-onend.sh"
	fi
	$JOYHELPDIR/rcfix.sh
	ASK_TO_REBOOT=1
	needtoinit=0
	whiptail --title "Joyhelp" --infobox "Joyhelp Initialized, please reboot to enable." 8 78
	sleep 3
	do_finish
}

do_disable() {
	# Restore backups if there are any...
	if [ -f "$CONFIGDIR/runcommand-onstart.sh.bakup" ]; then
		cp "$CONFIGDIR/runcommand-onstart.sh.bakup" "$CONFIGDIR/runcommand-onstart.sh"
	else
		rm -f "$CONFIGDIR/runcommand-onstart.sh"
	fi

	if [ -f "$CONFIGDIR/runcommand-onend.sh.bakup" ]; then
		cp "$CONFIGDIR/runcommand-onend.sh.bakup" "$CONFIGDIR/runcommand-onend.sh"
	else
		rm -f "$CONFIGDIR/runcommand-onend.sh"
	fi
	# Do some real work...
	if [ -f "/etc/rc.local.bakup" ]; then
		sudo cp /etc/rc.local /etc/rc.local.jh
		sudo cp /etc/rc.local.bakup /etc/rc.local
		whiptail --title "Joyhelp" --infobox "/etc/rc.local restored, Joyhelp configuration saved as /etc/rc.local.jh." 8 78
	else
		# crap, time to make a new rc.local file >:/
		# this should never happen, but here it goes...
		sudo cp /etc/rc.local /etc/rc.local.jh
		#configfile=/etc/rc.local
		TEMPFILE=$( cat "/etc/rc.local" )
		TEMPOUTFILE=""
		# make the file one line and replace newline with unique pattern
		echo "$TEMPFILE" > $JOYHELPDIR/.tempdfile1			## grab rc.local that is flat
		tr -s '\r' ' ' < $JOYHELPDIR/.tempdfile1 > $JOYHELPDIR/.tempdfile2
		sed ':a;N;$!ba;s|\n| jjjjjCLMjjjjj |g' $JOYHELPDIR/.tempdfile2 > $JOYHELPDIR/.tempdfile3
		found="no"
		TEMPFILE=$(cat "$JOYHELPDIR/.tempdfile3")		# This is the original (full) flartened/custom delimited rc.local
		delim="#######JOYHELP-CONFIG#######"
		for word in $TEMPFILE
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
					"JOYHELP")
					found="yes"
					;;
				esac
				if [ "$found" = "no" ]; then 
				TEMPOUTFILE=$TEMPOUTFILE" "$word
				fi
			done
		echo "$TEMPOUTFILE" > $JOYHELPDIR/.tempdfile1
		sed 's|jjjjjCLMjjjjj exit 0|\n|g' $JOYHELPDIR/.tempdfile1 > $JOYHELPDIR/.tempdfile2
		sed 's|jjjjjCLMjjjjj |\n|g' $JOYHELPDIR/.tempdfile2 > $JOYHELPDIR/.tempdfile3
		sed 's|jjjjjCLMjjjjj|\n|g' $JOYHELPDIR/.tempdfile3 > $JOYHELPDIR/.tempdfile4
		# wow, sed can remove \n\n
		sed 'N;/^\n$/D;P;D;' $JOYHELPDIR/.tempdfile4 > $JOYHELPDIR/.tempdfile2
		sed 's|  | |g' $JOYHELPDIR/.tempdfile2 > $JOYHELPDIR/.tempdfile1
		sed 's| #!/bin/sh|#!/bin/sh|g' $JOYHELPDIR/.tempdfile1 > $JOYHELPDIR/.rc-head
		
		# make sure we have an exit 0 at the end of new rc.local
		exitOK=$(cat "$JOYHELPDIR/.rc-head" | grep "exit 0")
		if [ "$exitOK" != "" ]; then
			echo "" >> $JOYHELPDIR/.rc-head
			echo "exit 0" >> $JOYHELPDIR/.rc-head
		fi
		
		sudo cp $JOYHELPDIR/.rc-head /etc/rc.local
		sudo rm $JOYHELPDIR/.tempdfile4
		sudo rm $JOYHELPDIR/.tempdfile3
		sudo rm $JOYHELPDIR/.tempdfile2
		sudo rm $JOYHELPDIR/.tempdfile1
		sudo rm $JOYHELPDIR/.rc-head
		whiptail --title "Joyhelp" --infobox "/etc/rc.local rebuilt, Joyhelp configuration saved as /etc/rc.local.jh." 8 78
	fi
sleep 3
ASK_TO_REBOOT=1
do_finish
}

do_system_read_config() {

## recursive
shopt -s globstar

for dir in $SYSCONFIGDIR/* ;do
	[[ ! -d $dir ]] && continue # if not directory then skip
	xtest=$(echo "$dir" | sed "s|$SYSCONFIGDIR\/||g" )
	if [ "$xtest" == "all" ] || [ "$xtest" == "ports" ]; then
		echo "joyhelp: ports " > /dev/null 2>&1
	else
		#systemlist=$systemlist" "$dir
		#echo "$xtest		$dir"
		#whatever="$whatever \"$xtest\" \"Edit or create $xtest config.\" \\ "
		whatever=$whatever" "$xtest" $dir "
	fi
done	
	
# do the same for the ports dir
for dir in $SYSCONFIGDIR/ports/* ;do
	[[ ! -d $dir ]] && continue # if not directory then skip
	xtest=$(echo "$dir" | sed "s|$SYSCONFIGDIR\/||g" )
	if [ "$xtest" == "all" ]; then
		echo "joyhelp: all " > /dev/null 2>&1
	else
		#systemlist=$systemlist" "$dir
		#echo "$xtest		$dir"
		#whatever="$whatever \"$xtest\" \"Edit or create $xtest config.\" \\ "
		whatever=$whatever" "$xtest" $dir "
	fi	
done
}

do_system_select() {
#systemlist=""
do_system_read_config
	RET=0
	while true; do
	  FUN=$(whiptail --title "Raspberry Pi Joyhelp: System-Specific Options" --menu "Default In-Game Setup Options" $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT --cancel-button Finish --ok-button Select \
		$whatever \
		3>&1 1>&2 2>&3)
	  RET=$?
	  if [ $RET -eq 1 ]; then
		#do_saveconfig_now
		#main_loop
		break
	  elif [ $RET -eq 0 ]; then
		# User selected a system... $FUN
		system="$FUN"
		# we need to make a variable with the full path to the config file... yay
		tempvar=""
		tempvar=$( echo "$FUN" | grep ports )
		if [ "$tempvar" ]; then
			# ports is in the name... we gotta do something about that...
			split=$( echo "$FUN" | sed -r "s|ports\/||" )
			systemfullpath=$SYSCONFIGDIR/ports/$split/joyhelp.cfg
			###  echo "$systemfullpath" & sleep 4
			
		else
			systemfullpath=$SYSCONFIGDIR/$FUN/joyhelp.cfg
			###  echo "$systemfullpath" & sleep 4
			
		fi
		
		if [ -f "$systemfullpath" ]; then
			#hey we found a config file, read it :D
			DEFCONTENT=$(cat $systemfullpath | sed -r '/[^=]+=[^=]+/!d' | sed -r 's/\s+=\s/=/g')
			eval "$DEFCONTENT"
			### echo "$DEFCONTENT" & sleep 1
		elif [ -f "$JOYHELPDIR/.configs/$FUN.cfg" ]; then
			#hey we found an included config file, read it :D
			DEFCONTENT=$(cat "$JOYHELPDIR/.configs/$FUN.cfg" | sed -r '/[^=]+=[^=]+/!d' | sed -r 's/\s+=\s/=/g')
			eval "$DEFCONTENT"
			### echo "$DEFCONTENT" & sleep 1
			sysconfigchanged=1
		else
			do_read_mainconfig
		fi
	  else
		exit 1
	  fi
	do_ingame_options

	done
}

do_sys_please_select() {
whiptail --title "System Select" --infobox "Please select a system first." 8 78
sleep 2
}

do_list_usb() {
usb=$( lsusb )
	xtemp=$( echo "$usb" | grep -v 1ea7: | grep -v "Super\ Gate" | grep -v "Standard\ Microsystems" | grep -v "4-Port\ HUB" | grep -v "root\ hub" )
	#xtemp=$( echo "$usb" | grep -v 1ea7: | grep -v "Super\ Gate" | grep -v "Standard\ Microsystems" )
	echo "$xtemp"
}

do_list_byid() {
usb=$( ls /dev/input/by-id/*-event-* )
	#xtemp=$( echo "$usb" | grep -v Mouse | grep -v mouse )
	xtemp=$( echo "$usb" | grep -v keyboard | grep -v Mouse | grep -v mouse )
	echo "$xtemp"
}

change_active_cont() {
	case $playerNum in
	0) playerNum=1 ;;
	1) playerNum=2 ;;
	2) playerNum=3 ;;
	3) playerNum=4 ;;
	4) playerNum="Disabled" ;;
	Disabled) playerNum=1 ;;
	esac
}

change_mimic() {
if ! [ "$playerNum" = "Disabled" ] && ! [ "$playerNum" = "0" ]; then
	case $mimic in
	Disabled) mimic="xpad" ;;
	xpad) mimic="xpad-wireless" ;;
	xpad-wireless) mimic="Disabled" ;;
	Disabled) mimic=1 ;;
	esac
fi
}

change_type() {
if ! [ "$playerNum" = "Disabled" ] && ! [ "$playerNum" = "0" ]; then
	case $type in
	Disabled) type="xbox360" ;;
	xbox360) type="xbox360-wireless" ;;
	xbox360-wireless) type="xbox360-guitar" ;;
	xbox360-guitar) type="xbox" ;;
	xbox) type="xbox-mat" ;;
	xbox-mat) type="Disabled" ;;
	esac
fi
}

do_pick_controller() {
	controllerID=""
	RET=0
	while true; do
	FUN=$(whiptail --title "Raspberry Pi Joyhelp: Select Controller by vendor:product" --menu "Default In-Game Setup Options" $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT --cancel-button Finish --ok-button Select \
		$whatever \
		3>&1 1>&2 2>&3)
	  RET=$?
	  if [ $RET -eq 1 ]; then
		exit 0
	  elif [ $RET -eq 0 ]; then
		echo "$FUN"
		break
	  else
		exit 1
	  fi
	done
}

do_select_player_number() {
	#playerNum=0
	RET=0
	while true; do
	FUN=$(whiptail --title "Raspberry Pi Joyhelp: Which Player?" --menu "Default In-Game Setup Options" $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT --cancel-button Finish --ok-button Select \
		"1" "Player 1" \
		"2" "Player 2" \
		"3" "Player 3" \
		"4" "Player 4" \
		3>&1 1>&2 2>&3)
	  RET=$?
	  if [ $RET -eq 1 ]; then
		break
	  elif [ $RET -eq 0 ]; then
		configchanged=1
		echo "$FUN"
		break
	  else
		exit 1
	  fi
	done
}

calc_wt_size

do_controller_setup() {
	#playerNum=0
	whatever=$( echo "$(do_list_usb)" | sed 's|Bus.....Device......ID.||g' | sed 's| | |' | sed 's| |_|g' | sed 's|_|\ |' | sed 's|\(.\)$|\1 |' )
	controllerID=$(do_pick_controller)
	if [ "$controllerID" ]; then
		if [ "$playerNum" = 0 ] || [ "$playerNum" = "Disabled" ]; then
			playerNum=$(do_select_player_number)
		fi
			case $playerNum in
				1) p1_id=$controllerID ;;
				2) p2_id=$controllerID ;;
				3) p3_id=$controllerID ;;
				4) p4_id=$controllerID ;;
				*) ;;
			esac
	fi
	if [ "$controllerID" ]; then
		whiptail --title "Joyhelp: Identify Controller" --infobox "$controllerID selected." 8 $WT_WIDTH
		sleep 2
		configchanged=1
	fi
}

do_controller_setup_byid() {
	#playerNum=0
	whatever=$( echo "$(do_list_byid)" | tr "©" "?" | sed "s|'||" | sed 's|\(.\)$|\1 Controller |' )
	controllerID=$(do_pick_controller)
	temp=$( echo $controllerID | head -c 22 )
	if [ "$temp" = "/dev/input/by-id/usb-?" ]; then			## remove © from the ID or it won't work
		temp=$( echo $controllerID | sed "s|usb-|usb|" )	## ugly hack =D
		controllerID=$temp
	fi
	if [ "$controllerID" ]; then
		if [ "$playerNum" = 0 ] || [ "$playerNum" = "Disabled" ]; then
			playerNum=$(do_select_player_number)
		fi
		case $playerNum in
			1) p1_bid=$controllerID ;;
			2) p2_bid=$controllerID ;;
			3) p3_bid=$controllerID ;;
			4) p4_bid=$controllerID ;;
			*) ;;
		esac
	fi
	if [ "$controllerID" ]; then
		whiptail --title "Joyhelp: Identify Controller" --infobox "$controllerID selected." 8 $WT_WIDTH
		sleep 2
		configchanged=1
	fi
}

do_setup_controller() {
	while true; do
	  FUN=$(whiptail --title "Raspberry Pi Joyhelp: Configure Controller" --menu "GUI Setup Options" $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT --cancel-button Finish --ok-button Select \
		"1 Active Controller = $playerNum" "" \
		"2 Identify Controller" "Configure controller: VEND:PROD" \
		"3 Identify Controller" "Configure controller: by-id" \
		"4 Mimic: $mimic" "" \
		"5 Type: $type" "" \
		3>&1 1>&2 2>&3)
	  RET=$?
	  if [ $RET -eq 1 ]; then
		do_saveconfig_now
		break
	  elif [ $RET -eq 0 ]; then
		case "$FUN" in
		  1\ *) change_active_cont ;;
		  2\ *) do_controller_setup ;; 
		  3\ *) do_controller_setup_byid ;;
		  4\ *) change_mimic ;;
		  5\ *) change_type ;;
		  *) whiptail --msgbox "Programmer error: unrecognized option" 20 60 1 ;;
		esac || whiptail --msgbox "There was an error running option $FUN" 20 60 1
	  else
		exit 1
	  fi
	done
}

do_gui_options() {
	RET=0
	while true; do
	  FUN=$(whiptail --title "Raspberry Pi Joyhelp: joyhelp.cfg Options" --menu "GUI Setup Options" $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT --cancel-button Finish --ok-button Select \
		"1 Xboxdrv sudo = $sudoForced" "Force Xboxdrv to run as sudo?" \
		"2 Xboxdrv = $xboxdrvrp" "Default (launch) Setting: 0=Disable,1=Enable,3=Daemon" \
		"3 Xpad = $xpadrp" "Default (launch) Setting: 0=Disable,1=Enable" \
		"4 Debug = $debug" "Logs to $logfile" \
		"5 Xboxdrv = $xboxdrv" "Default In-Game Setting: 0=Disable,1=Enable" \
		"6 Xpad = $xpad" "Default In-Game Setting: 0=Disable,1=Enable" \
		"7 System-Specific Options" "Edit Xpad/Xboxdrv system-specific config" \
		3>&1 1>&2 2>&3)
	  RET=$?
	  if [ $RET -eq 1 ]; then
		do_saveconfig_now
		#main_loop
		#false
	  elif [ $RET -eq 0 ]; then
		case "$FUN" in
		  1\ *) do_xboxdrv_sudo ;;
		  2\ *) do_xboxdrv_toggle ;;
		  3\ *) do_xpad_toggle ;;
		  4\ *) do_debug_toggle ;;
		  5\ *) do_xboxdrvg_toggle ;;
		  6\ *) do_xpadg_toggle ;;
		  7\ *) do_ingame_options ;;
		  *) whiptail --msgbox "Programmer error: unrecognized option" 20 60 1 ;;
		esac || whiptail --msgbox "There was an error running option $FUN" 20 60 1
	  else
		exit 1
	  fi
	done
}

do_ingame_options() {
RET="0"
if [ "$system" = "Not_Selected" ]; then			## we have not selected a system yet
	while true; do
	  FUN=$(whiptail --title "Raspberry Pi Joyhelp: System-Specific Options" --menu "Default In-Game Setup Options" $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT --cancel-button Finish --ok-button Select \
		"1 Select System: $system" "System-specific config to edit" \
		"X Xboxdrv = $xboxdrv" "In-Game Setting: 0=Disable,1=Enable." \
		"X Xpad = $xpad" "In-Game Setting: 0=Disable,1=Enable." \
		"X p1_profile" "$p1_profile" \
		"X p2_profile" "$p2_profile" \
		"X p3_profile" "$p3_profile" \
		"X p4_profile" "$p4_profile" \
		"X Arcade ROM Lists = $arcaderomlists" "Use arcade ROM lists." \
		"X   4-Way games" "\"$arcaderom4way\"" \
		"X   Dial games" "\"$arcaderomdial\"" \
		"X   Trackball games" "\"$arcaderomtrackball\"" \
		"X   Analog games" "\"$arcaderomanalog\"" \
		3>&1 1>&2 2>&3)
	  RET=$?
	  if [ $RET -eq 1 ]; then
		do_saveconfig_now
		main_loop
		#false
	  elif [ $RET -eq 0 ]; then
		case "$FUN" in
		  1\ *) do_system_select ;;
		  X\ *) do_sys_please_select ;;
		  *) whiptail --msgbox "Programmer error: unrecognized option" 20 60 1 ;;
		esac || whiptail --msgbox "There was an error running option $FUN" 20 60 1
	  else
		exit 1
	  fi
	done
else
	while true; do
	  FUN=$(whiptail --title "Raspberry Pi Joyhelp: System-Specific Options" --menu "Default In-Game Setup Options" $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT --cancel-button Finish --ok-button Select \
		"1 Select System: $system" "System-specific config to edit" \
		"2 Xboxdrv = $xboxdrv" "$xboxdrv setting: 0=Disable,1=Enable." \
		"3 Xpad = $xpad" "$xpad setting: 0=Disable,1=Enable." \
		"4 p1_profile" "$p1_profile" \
		"5 p2_profile" "$p2_profile" \
		"6 p3_profile" "$p3_profile" \
		"7 p4_profile" "$p4_profile" \
		"8 Arcade ROM Lists = $arcaderomlists" "Use arcade ROM lists." \
		"9    4-Way games" "\"$arcaderom4way\"" \
		"10   Dial games" "\"$arcaderomdial\"" \
		"11   Trackball games" "\"$arcaderomtrackball\"" \
		"12   Analog games" "\"$arcaderomanalog\"" \
		3>&1 1>&2 2>&3)
	  RET=$?
	  if [ $RET -eq 1 ]; then
		do_savesysconfig_now
		break 3
		#false
	  elif [ $RET -eq 0 ]; then
		case "$FUN" in
		  1\ *) do_system_select ;;
		  2\ *) do_xboxdrvs_toggle ;;
		  3\ *) do_xpads_toggle ;;
		  4\ *) do_p1_profile ;;
		  5\ *) do_p2_profile ;;
		  6\ *) do_p3_profile ;;
		  7\ *) do_p4_profile ;;
		  8\ *) arc_romlist_toggle ;;
		  9\ *) arc_fourway ;;
		  10\ *) arc_dial ;;
		  11\ *) arc_trackball ;;
		  12\ *) arc_analog ;;
		  *) whiptail --msgbox "Programmer error: unrecognized option" 20 60 1 ;;
		esac || whiptail --msgbox "There was an error running option $FUN" 20 60 1
	  else
		exit 1
	  fi
	done
fi
}

main_loop() {
#
# Interactive use loop
#
calc_wt_size
if [ "$needtoinit" = "1" ]; then
	while true; do
	  FUN=$(whiptail --title "Raspberry Pi Joyhelp: Main Menu" --menu "Default Setup Options" $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT --cancel-button Finish --ok-button Select \
		"X Xboxdrv sudo = $sudoForced" "Force Xboxdrv to run as sudo?" \
		"X Xboxdrv = $xboxdrvrp" "Default (launch) Setting: 0=Disable,1=Enable,3=Daemon." \
		"X Xpad = $xpadrp" "Default (launch) Setting: 0=Disable,1=Enable." \
		"X Debug = $debug" "Logs to $logfile." \
		"X Xboxdrv = $xboxdrv" "Default In-Game Setting: 0=Disable,1=Enable." \
		"X Xpad = $xpad" "Default In-Game Setting: 0=Disable,1=Enable." \
		"X System-Specific Options" "Edit Xpad/Xboxdrv system-specific config." \
		"8 Swap Joystick 0 and 1" "In retroarch systems only." \
		"9 About Joyhelp" "About this program." \
		"10 Initialize Joyhelp" "Generate config files for Joyhelp." \
		"X Disable Joyhelp" "Restore default rc.local file." \
		3>&1 1>&2 2>&3)
	  RET=$?
	  if [ $RET -eq 1 ]; then
		do_finish
	  elif [ $RET -eq 0 ]; then
		case "$FUN" in
		  1\ *) do_xboxdrv_sudo ;;
		  2\ *) do_xboxdrv_toggle ;;
		  3\ *) do_xpad_toggle ;;
		  4\ *) do_debug_toggle ;;
		  5\ *) do_xboxdrvg_toggle ;;
		  6\ *) do_xpadg_toggle ;;
		  7\ *) do_ingame_options ;;
		  8\ *) do_joy_swap ;;
		  9\ *) do_about ;;
		  10\ *) do_init ;;
		  11\ *) do_disable ;;
		  X\ *) do_please_init ;;
		  *) whiptail --msgbox "Programmer error: unrecognized option" 20 60 1 ;;
		esac || whiptail --msgbox "There was an error running option $FUN" 20 60 1
	  else
		exit 1
	  fi
	do_finish
	done
else
	while true; do
	  FUN=$(whiptail --title "Raspberry Pi Joyhelp: Main Menu" --menu "Setup Options" $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT --cancel-button Finish --ok-button Select \
		"1 Xboxdrv sudo = $sudoForced" "Force Xboxdrv to run as sudo?" \
		"2 Xboxdrv = $xboxdrvrp" "Default (launch) Setting: 0=Disable,1=Enable,3=Daemon." \
		"3 Xpad = $xpadrp" "Default (launch) Setting: 0=Disable,1=Enable." \
		"4 Debug = $debug" "Logs to $logfile." \
		"5 Xboxdrv = $xboxdrv" "Default In-Game Setting: 0=Disable,1=Enable." \
		"6 Xpad = $xpad" "Default In-Game Setting: 0=Disable,1=Enable." \
		"7 System-Specific Options" "Edit Xpad/Xboxdrv system-specific config." \
		"8 Swap Joystick 0 and 1" "In retroarch systems only." \
		"a identify controller" "BETA OPTION: works, sort of..." \
		"b Controller Setup" "BETA OPTION: works, sort of..." \
		"9 About Joyhelp" "About this program." \
		"10 Initialize Joyhelp" "Generate config files for Joyhelp." \
		"11 Disable Joyhelp" "Restore default rc.local file." \
		3>&1 1>&2 2>&3)
	  RET=$?
	  if [ $RET -eq 1 ]; then
		do_finish
	  elif [ $RET -eq 0 ]; then
		case "$FUN" in
		  a\ *) playerNum="Disabled"; do_controller_setup; do_controller_setup_byid ;;
		  b\ *) do_setup_controller ;;
		  1\ *) do_xboxdrv_sudo ;;
		  2\ *) do_xboxdrv_toggle ;;
		  3\ *) do_xpad_toggle ;;
		  4\ *) do_debug_toggle ;;
		  5\ *) do_xboxdrvg_toggle ;;
		  6\ *) do_xpadg_toggle ;;
		  7\ *) do_ingame_options ;;
		  8\ *) do_joy_swap ;;
		  9\ *) do_about ;;
		  10\ *) do_init ;;
		  11\ *) do_disable ;;
		  *) whiptail --msgbox "Programmer error: unrecognized option" 20 60 1 ;;
		esac || whiptail --msgbox "There was an error running option $FUN" 20 60 1
	  else
		exit 1
	  fi
	#do_finish  
	done
fi
}

main_loop

exit 0