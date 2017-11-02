#!/bin/bash
# strip the daemon command from joyhelp-config.cfg
# and create joyhelp-nodaemon.cfg
#

# todo remove temp files and use variables

# JOYHELP DIRECTORIES
# maybe these could change...
CONFIGDIR=/opt/retropie/configs/all
JOYHELPDIR=$CONFIGDIR/joyhelp
DEFCFG=$JOYHELPDIR/joyhelp.cfg		# this is the control config file...
logfile=$JOYHELPDIR/joyhelp.log
configfile=$JOYHELPDIR/joyhelp-config.cfg	# this is the xboxdrv config file
basicXBOX=$(cat "$configfile")
#################

#check for daemon mode in config file...
daemon=$(cat "$configfile" | grep daemon)
if [ "$daemon" = "" ]; then
	daemon=$(cat "$configfile" | grep "\-D\s" )
fi
#check for sudo in config file...
sudo=""
sudo=$(cat "$configfile" | grep sudo)

do_read_config() {
# Read default RetroPie Joyhelp (GUI) config file...

if [ -f "$DEFCFG" ]
then
  DEFCONTENT=$(cat $DEFCFG | sed -r '/[^=]+=[^=]+/!d' | sed -r 's/\s+=\s/=/g')
  eval "$DEFCONTENT"
  #echo "$DEFCONTENT"
else
	echo "Main config file not found: $DEFCFG"
	#exit 1
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

if [ "$debug" = "1" ]; then echo "configfix: running - $(date)" >> $logfile; fi
}


# declare some variables
sudoForced=0
silent=0

# read config file
do_read_config

# strip '--daemon'
sed 's/--daemon/ /g' $configfile > $JOYHELPDIR/.tempxfile2
# strip '-D'
sed 's/-D / /g' $JOYHELPDIR/.tempxfile2 > $JOYHELPDIR/.tempxfile3
# make it a one line command, wth
sed 's/\\//g' $JOYHELPDIR/.tempxfile3 > $JOYHELPDIR/.tempxfile4
tr -d '\n' < $JOYHELPDIR/.tempxfile4 > $JOYHELPDIR/.tempxfile3
tr -d '\r' < $JOYHELPDIR/.tempxfile3 > $JOYHELPDIR/.tempxfile2
sed 's/sudo//g' $JOYHELPDIR/.tempxfile2 > $JOYHELPDIR/.tempxfile3
sed 's/&/& /g' $JOYHELPDIR/.tempxfile3 > $JOYHELPDIR/.tempxfile4
sed 's/sleep 1//g' $JOYHELPDIR/.tempxfile4 > $JOYHELPDIR/.tempxfile3
sed 's/sleep 2//g' $JOYHELPDIR/.tempxfile3 > $JOYHELPDIR/.tempxfile2
sed 's/  / /g' $JOYHELPDIR/.tempxfile2 > $JOYHELPDIR/.tempxfile1
sed 's/\"//g' $JOYHELPDIR/.tempxfile1 > $JOYHELPDIR/.tempxfile3
string="$(cat $JOYHELPDIR/.tempxfile3)"
stripped=$(echo $string | xargs)		# trim trailing spaces of next part won't work right...

# read last character and see if it's okay
test=$(echo $stripped | tail -c 2 )		
if [ "$test" = "&" ]  # our file ends with a '&' we don't want that...
then
	echo "${stripped%?}" > $JOYHELPDIR/.tempxfile2
	# now that we've removed the trailing '&' we can replace all the other ampersands (for compatability)
	sed 's/&/--next-controller/g' $JOYHELPDIR/.tempxfile2 > $JOYHELPDIR/.tempxfile4
fi

## hopefully at this point, no matter what the input our config may be in (almost) the same format....

sed 's/--dbus disabled/--dbusdisabled/g' $JOYHELPDIR/.tempxfile4 > $JOYHELPDIR/.tempxfile3
sed 's/--dbus session/--dbussession/g' $JOYHELPDIR/.tempxfile3 > $JOYHELPDIR/.tempxfile2
sed 's/--dbus system/--dbussystem/g' $JOYHELPDIR/.tempxfile2 > $JOYHELPDIR/.tempxfile1
sed 's|#||g' $JOYHELPDIR/.tempxfile1 > $JOYHELPDIR/.tempxfile2
sed 's/--dbus auto/--dbusauto/g' $JOYHELPDIR/.tempxfile2 > $JOYHELPDIR/.tempxfile4

# let's clean up
rm -f $JOYHELPDIR/.tempxfile
rm -f $JOYHELPDIR/.tempxfile1
rm -f $JOYHELPDIR/.tempxfile2
rm -f $JOYHELPDIR/.tempxfile3

#######################################

if [ "$debug" = "1" ]; then echo "configfix: running - $(date)" >> $logfile; fi
if [ "$debug" = "1" ]; then echo "configfix: Original Config:  $(cat $configfile)" >> $logfile; fi

string="$(cat $JOYHELPDIR/.tempxfile4)"
if [ "$debug" = "1" ]; then echo "configfix: Pre-processed Config: $string" >> $logfile; fi
outfile=""
player=12
prefix=""
p1_config=""
p2_config=""
p3_config=""
p4_config=""
tempfile=""
suffix=""
delim="--next-controller"
delimb="&"
detach=0
detachKD=0
dbus=0

# start our prefix/suffix files...

for word in $string
	do
		if [ "$player" = 12 ]; then		# I assume this is the actual xboxdrv command...
			prefix=$word
			word=""
			player=1
		fi
		
		case $word in			# we don't want the command in our player files...
			*xboxdrv)
			word=""
			;;
			esac
			
		
		if [ "$word" = "--detach-kernel-driver" ]
		then
			detachKD=1
			word=""
		fi
		if [ "$word" = "--detach" ]
		then
			detach=1
			word=""
		fi
		if [ "$word" = "--dbusauto" ] 
		then
			dbus=0
			word=""
		fi
		if [ "$word" = "--dbussession" ] 
		then
			dbus=1
			word=""
		fi
		if [ "$word" = "--dbussystem" ] 
		then
			dbus=2
			word=""
		fi
		if [ "$word" = "--dbusdisabled" ] 
		then
			dbus=3
			word=""
		fi
		if [ "$word" = "--silent" ] 
		then
			silent=1
			word=""
		fi
		if [ "$word" = "--four-way-restrictor" ] 
		then
			word=""
		fi
		if [ "$word" = "--square-axis" ] 
		then
			word=""
		fi
		if [ "$word" = "$delim" ] || [ "$word" = "$delimb" ]
		then
			if [ "$player" = 4 ]
			then
				p4_config=$(echo $outfile | xargs)
				if [ "$debug" = "1" ]; then echo "configfix: P4 Config: $p4_config" >> $logfile; fi
				outfile=""
				player=$(( player+1 ))
			fi
			if [ "$player" = 3 ]
			then
				p3_config=$(echo $outfile | xargs)
				if [ "$debug" = "1" ]; then echo "configfix: P3 Config: $p3_config" >> $logfile; fi
				outfile=""
				player=$(( player+1 ))
			fi
			if [ "$player" = 2 ]
			then
					p2_config=$(echo $outfile | xargs)
					if [ "$debug" = "1" ]; then echo "configfix: P2 Config: $p2_config" >> $logfile; fi
					outfile=""
					player=$(( player+1 ))
			fi
			if [ "$player" = 1 ]
			then
					p1_config=$(echo $outfile | xargs)
					if [ "$debug" = "1" ]; then echo "configfix: P1 Config: $p1_config" >> $logfile; fi
					outfile=""
					player=$(( player+1 ))
			fi
		else
		outfile=$outfile" "$word
		fi
	done

if [ "$player" = 4 ]
then
	p4_config=$(echo $outfile | xargs)
	if [ "$debug" = "1" ]; then echo "configfix: P4 Config: $p4_config" >> $logfile; fi
fi
if [ "$player" = 3 ]
then
	p3_config=$(echo $outfile | xargs)
	if [ "$debug" = "1" ]; then echo "configfix: P3 Config: $p3_config" >> $logfile; fi
fi
if [ "$player" = 2 ]
then
	p2_config=$(echo $outfile | xargs)
	if [ "$debug" = "1" ]; then echo "configfix: P2 Config: $p2_config" >> $logfile; fi
fi
if [ "$player" = 1 ]
then
	p1_config=$(echo $outfile | xargs)
	if [ "$debug" = "1" ]; then echo "configfix: P1 Config: $p1_config" >> $logfile; fi
fi

if [ "$dbus" = 0 ] ; then
	temp=$suffix
	suffix="$temp --dbus auto"
fi
if [ "$dbus" = 1 ] ; then
	temp=$suffix
	suffix="$temp --dbus session"
fi
if [ "$dbus" = 2 ] ; then
	temp=$suffix
	suffix="$temp --dbus system"
fi
if [ "$dbus" = 3 ] ; then
	temp=$suffix
	suffix="$temp --dbus disabled"
fi
if [ "$detachKD" = 1 ] ; then
	temp=$suffix
	suffix="$temp --detach-kernel-driver"
fi
if [ "$silent" = 1 ] ; then
	temp=$suffix
	suffix="$temp --silent"
fi
prefix=$(echo $prefix | xargs)
suffix=$(echo $suffix | xargs)
p1_config=$(echo "$p1_config" | xargs)
p2_config=$(echo "$p2_config" | xargs)
p3_config=$(echo "$p3_config" | xargs)
p4_config=$(echo "$p4_config" | xargs)

if [ "$debug" = "1" ]; then echo "configfix: Prefix: $prefix" >> $logfile; fi
if [ "$debug" = "1" ]; then echo "configfix: Suffix: $suffix" >> $logfile; fi

# Clean up again
rm -f $JOYHELPDIR/.tempxfile4
rm -f $JOYHELPDIR/.tempxfile3

## these are needed for the runcommand-onstart.sh
# Quit commenting this out!!!    =D
echo "$prefix" > $JOYHELPDIR/.scripts/.xbd_prefix
echo "$suffix" > $JOYHELPDIR/.scripts/.xbd_suffix
echo "$p1_config" > $JOYHELPDIR/.scripts/.xbd_p1config
echo "$p2_config" > $JOYHELPDIR/.scripts/.xbd_p2config
echo "$p3_config" > $JOYHELPDIR/.scripts/.xbd_p3config
echo "$p4_config" > $JOYHELPDIR/.scripts/.xbd_p4config

# Let's build some config files...
count="2"

## # xboxdrv run as sudo?
# # sudoForced = 1
# so we don't want to hardcode the command into the launch file...
if [ "$sudoForced" = 1 ]; then
	sudo="true"
fi

if [ "$sudo" ]; then
	prefix="sudo $prefix"
fi

if [ "$detach" = 1 ] ; then
	configD="$prefix --detach --daemon $p1_config "
else
	configD="$prefix --daemon $p1_config "
fi

if [ "$silent" = 1 ] ; then
	echo "$prefix $p1_config --silent &" > $JOYHELPDIR/joyhelp-nodaemon.cfg
else
	echo "$prefix $p1_config &" > $JOYHELPDIR/joyhelp-nodaemon.cfg
fi


while [ $count -le $player ]
do
	case $count in
		2)
		echo "sleep 1" >> $JOYHELPDIR/joyhelp-nodaemon.cfg
		if [ "$silent" = 1 ] ; then
			echo "$prefix $p2_config --silent &" >> $JOYHELPDIR/joyhelp-nodaemon.cfg
		else
			echo "$prefix $p2_config &" >> $JOYHELPDIR/joyhelp-nodaemon.cfg
		fi
		configD="$configD --next-controller $p2_config"
		;;
		3)
		echo "sleep 1" >> $JOYHELPDIR/joyhelp-nodaemon.cfg
		if [ "$silent" = 1 ] ; then
			echo "$prefix $p3_config --silent &" >> $JOYHELPDIR/joyhelp-nodaemon.cfg
		else
			echo "$prefix $p3_config &" >> $JOYHELPDIR/joyhelp-nodaemon.cfg
		fi
		configD="$configD --next-controller $p3_config"
		;;
		4)
		echo "sleep 1" >> $JOYHELPDIR/joyhelp-nodaemon.cfg
		if [ "$silent" = 1 ] ; then
			echo "$prefix $p4_config --silent &" >> $JOYHELPDIR/joyhelp-nodaemon.cfg
		else
			echo "$prefix $p4_config &" >> $JOYHELPDIR/joyhelp-nodaemon.cfg
		fi
		configD="$configD --next-controller $p4_config"
		;;
		*)
		echo
		;;
	esac
	count=$(( count+1 ))	
done
configD="$configD $suffix"
# create write config for daemon mode
echo "$configD" > $JOYHELPDIR/joyhelp-daemon.cfg

# copy original config file to .old 
# so if the config has not changed
# rc.local helper script won't call
# configfig.sh
cp $JOYHELPDIR/joyhelp-config.cfg $JOYHELPDIR/joyhelp-config.old

#######################################

# Fix the permissions of the files
sudo chown pi:pi $JOYHELPDIR/joyhelp-config.cfg
sudo chown pi:pi $JOYHELPDIR/joyhelp-config.old
sudo chown pi:pi $JOYHELPDIR/joyhelp-daemon.cfg
sudo chown pi:pi $JOYHELPDIR/joyhelp-nodaemon.cfg
sudo chmod +x $JOYHELPDIR/joyhelp-config.cfg
sudo chmod +x $JOYHELPDIR/joyhelp-daemon.cfg
sudo chmod +x $JOYHELPDIR/joyhelp-nodaemon.cfg
sudo chmod +x /opt/retropie/configs/all/runcommand-onend.sh
sudo chmod +x /opt/retropie/configs/all/runcommand-onstart.sh
sudo chown pi:pi $JOYHELPDIR/.scripts/.xbd_prefix
sudo chown pi:pi $JOYHELPDIR/.scripts/.xbd_suffix
sudo chown pi:pi $JOYHELPDIR/.scripts/.xbd_p1config
sudo chown pi:pi $JOYHELPDIR/.scripts/.xbd_p2config
sudo chown pi:pi $JOYHELPDIR/.scripts/.xbd_p3config
sudo chown pi:pi $JOYHELPDIR/.scripts/.xbd_p4config
sudo chmod +x $JOYHELPDIR/.scripts/.xbd_prefix
sudo chmod +x $JOYHELPDIR/.scripts/.xbd_suffix
sudo chmod +x $JOYHELPDIR/.scripts/.xbd_p1config
sudo chmod +x $JOYHELPDIR/.scripts/.xbd_p2config
sudo chmod +x $JOYHELPDIR/.scripts/.xbd_p3config
sudo chmod +x $JOYHELPDIR/.scripts/.xbd_p4config

# Made it to the end
exit 0