#!/bin/sh
# strip the daemon command from joyhelp-config.cfg
# and create joyhelp-nodaemon.cfg
#

## Force sudo ?
#sudoForced="0"
sudoForced="1"

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
#################


#check for daemon mode in config file...
daemon=$(cat "$configfile" | grep daemon)
if [ "$daemon" = "" ]; then
	daemon=$(cat "$configfile" | grep "\-D\s" )
fi
#check for sudo in config file...
sudo=""
sudo=$(cat "$configfile" | grep sudo)

# want more output?
# change DBG to "1"
DBG="0"

if [ "$MODE" = "5" ] || [ "$MODE" = "6" ] || [ "$MODE" = "7" ] || [ "$MODE" = "8" ] || [ "$MODE" = "9" ]
then
	DBG="1"
fi
if [ "$DBG" = "1" ]; then echo "configfix: running - $(date)" >> $LOGFILE; fi



# strip '--daemon'
sed 's/--daemon/ /g' $configfile > $XBDRDIR/.tempxfile2
# strip '-D'
sed 's/-D / /g' $XBDRDIR/.tempxfile2 > $XBDRDIR/.tempxfile3
# make it a one line command, wth
sed 's/\\//g' $XBDRDIR/.tempxfile3 > $XBDRDIR/.tempxfile4
tr -d '\n' < $XBDRDIR/.tempxfile4 > $XBDRDIR/.tempxfile3
tr -d '\r' < $XBDRDIR/.tempxfile3 > $XBDRDIR/.tempxfile2
sed 's/sudo//g' $XBDRDIR/.tempxfile2 > $XBDRDIR/.tempxfile3
sed 's/&/& /g' $XBDRDIR/.tempxfile3 > $XBDRDIR/.tempxfile4
sed 's/sleep 1//g' $XBDRDIR/.tempxfile4 > $XBDRDIR/.tempxfile3
sed 's/sleep 2//g' $XBDRDIR/.tempxfile3 > $XBDRDIR/.tempxfile2
sed 's/  / /g' $XBDRDIR/.tempxfile2 > $XBDRDIR/.tempxfile1
sed 's/\"//g' $XBDRDIR/.tempxfile1 > $XBDRDIR/.tempxfile3
string="$(cat $XBDRDIR/.tempxfile3)"
stripped=$(echo $string | xargs)		# trim trailing spaces of next part won't work right...

# read last character and see if it's okay
test=$(echo $stripped | tail -c 2 )		
if [ "$test" = "&" ]  # our file ends with a '&' we don't want that...
then
	echo "${stripped%?}" > $XBDRDIR/.tempxfile2
	# now that we've removed the trailing '&' we can replace all the other ampersands (for compatability)
	sed 's/&/--next-controller/g' $XBDRDIR/.tempxfile2 > $XBDRDIR/.tempxfile4
fi

## hopefully at this point, no matter what the input our config may be in (almost) the same format....

sed 's/--dbus disabled/--dbusdisabled/g' $XBDRDIR/.tempxfile4 > $XBDRDIR/.tempxfile3
sed 's/--dbus session/--dbussession/g' $XBDRDIR/.tempxfile3 > $XBDRDIR/.tempxfile2
sed 's/--dbus system/--dbussystem/g' $XBDRDIR/.tempxfile2 > $XBDRDIR/.tempxfile1
sed 's|#||g' $XBDRDIR/.tempxfile1 > $XBDRDIR/.tempxfile2
sed 's/--dbus auto/--dbusauto/g' $XBDRDIR/.tempxfile2 > $XBDRDIR/.tempxfile4

# let's clean up
rm -f $XBDRDIR/.tempxfile
rm -f $XBDRDIR/.tempxfile1
rm -f $XBDRDIR/.tempxfile2
rm -f $XBDRDIR/.tempxfile3

#######################################

if [ "$DBG" = "1" ]; then echo "configfix: running - $(date)" >> $LOGFILE; fi
if [ "$DBG" = "1" ]; then echo "configfix: Original Config:  $(cat $configfile)" >> $LOGFILE; fi

string="$(cat $XBDRDIR/.tempxfile4)"
if [ "$DBG" = "1" ]; then echo "configfix: Pre-processed Config: $string" >> $LOGFILE; fi
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
silent=0

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
				if [ "$DBG" = "1" ]; then echo "configfix: P4 Config: $p4_config" >> $LOGFILE; fi
				outfile=""
				player=$(( player+1 ))
			fi
			if [ "$player" = 3 ]
			then
				p3_config=$(echo $outfile | xargs)
				if [ "$DBG" = "1" ]; then echo "configfix: P3 Config: $p3_config" >> $LOGFILE; fi
				outfile=""
				player=$(( player+1 ))
			fi
			if [ "$player" = 2 ]
			then
					p2_config=$(echo $outfile | xargs)
					if [ "$DBG" = "1" ]; then echo "configfix: P2 Config: $p2_config" >> $LOGFILE; fi
					outfile=""
					player=$(( player+1 ))
			fi
			if [ "$player" = 1 ]
			then
					p1_config=$(echo $outfile | xargs)
					if [ "$DBG" = "1" ]; then echo "configfix: P1 Config: $p1_config" >> $LOGFILE; fi
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
	if [ "$DBG" = "1" ]; then echo "configfix: P4 Config: $p4_config" >> $LOGFILE; fi
fi
if [ "$player" = 3 ]
then
	p3_config=$(echo $outfile | xargs)
	if [ "$DBG" = "1" ]; then echo "configfix: P3 Config: $p3_config" >> $LOGFILE; fi
fi
if [ "$player" = 2 ]
then
	p2_config=$(echo $outfile | xargs)
	if [ "$DBG" = "1" ]; then echo "configfix: P2 Config: $p2_config" >> $LOGFILE; fi
fi
if [ "$player" = 1 ]
then
	p1_config=$(echo $outfile | xargs)
	if [ "$DBG" = "1" ]; then echo "configfix: P1 Config: $p1_config" >> $LOGFILE; fi
fi

if [ "$dbus" = 0 ] ; then
	temp=$suffix
	suffix="$temp --dbus audo"
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

if [ "$DBG" = "1" ]; then echo "configfix: Prefix: $prefix" >> $LOGFILE; fi
if [ "$DBG" = "1" ]; then echo "configfix: Suffix: $suffix" >> $LOGFILE; fi

# Clean up again
rm -f $XBDRDIR/.tempxfile4
rm -f $XBDRDIR/.tempxfile3

## these are needed for the runcommand-onstart.sh
# Quit commenting this out!!!    =D
echo "$prefix" > $XBDRDIR/.xbd_prefix
echo "$suffix" > $XBDRDIR/.xbd_suffix
echo "$p1_config" > $XBDRDIR/.xbd_p1config
echo "$p2_config" > $XBDRDIR/.xbd_p2config
echo "$p3_config" > $XBDRDIR/.xbd_p3config
echo "$p4_config" > $XBDRDIR/.xbd_p4config

# Let's build some config files...
count="2"

if [ $sudoForced = "1" ]; then
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
	echo "$prefix $p1_config --silent &" > $XBDRDIR/joyhelp-nodaemon.cfg
else
	echo "$prefix $p1_config &" > $XBDRDIR/joyhelp-nodaemon.cfg
fi


while [ $count -le $player ]
do
	case $count in
		2)
		echo "sleep 1" >> $XBDRDIR/joyhelp-nodaemon.cfg
		if [ "$silent" = 1 ] ; then
			echo "$prefix $p2_config --silent &" >> $XBDRDIR/joyhelp-nodaemon.cfg
		else
			echo "$prefix $p2_config &" >> $XBDRDIR/joyhelp-nodaemon.cfg
		fi
		configD="$configD --next-controller $p2_config"
		;;
		3)
		echo "sleep 1" >> $XBDRDIR/joyhelp-nodaemon.cfg
		if [ "$silent" = 1 ] ; then
			echo "$prefix $p3_config --silent &" >> $XBDRDIR/joyhelp-nodaemon.cfg
		else
			echo "$prefix $p3_config &" >> $XBDRDIR/joyhelp-nodaemon.cfg
		fi
		configD="$configD --next-controller $p3_config"
		;;
		4)
		echo "sleep 1" >> $XBDRDIR/joyhelp-nodaemon.cfg
		if [ "$silent" = 1 ] ; then
			echo "$prefix $p4_config --silent &" >> $XBDRDIR/joyhelp-nodaemon.cfg
		else
			echo "$prefix $p4_config &" >> $XBDRDIR/joyhelp-nodaemon.cfg
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
echo "$configD" > $XBDRDIR/joyhelp-daemon.cfg

#######################################

# Fix the permissions of the files
sudo chown pi:pi $XBDRDIR/joyhelp-config.cfg
sudo chown pi:pi $XBDRDIR/joyhelp-daemon.cfg
sudo chown pi:pi $XBDRDIR/joyhelp-nodaemon.cfg
sudo chmod +x $XBDRDIR/joyhelp-config.cfg
sudo chmod +x $XBDRDIR/joyhelp-daemon.cfg
sudo chmod +x $XBDRDIR/joyhelp-nodaemon.cfg
sudo chmod +x /opt/retropie/configs/all/runcommand-onend.sh
sudo chmod +x /opt/retropie/configs/all/runcommand-onstart.sh
sudo chown pi:pi $XBDRDIR/.xbd_prefix
sudo chown pi:pi $XBDRDIR/.xbd_suffix
sudo chown pi:pi $XBDRDIR/.xbd_p1config
sudo chown pi:pi $XBDRDIR/.xbd_p2config
sudo chown pi:pi $XBDRDIR/.xbd_p3config
sudo chown pi:pi $XBDRDIR/.xbd_p4config
sudo chmod +x $XBDRDIR/.xbd_prefix
sudo chmod +x $XBDRDIR/.xbd_suffix
sudo chmod +x $XBDRDIR/.xbd_p1config
sudo chmod +x $XBDRDIR/.xbd_p2config
sudo chmod +x $XBDRDIR/.xbd_p3config
sudo chmod +x $XBDRDIR/.xbd_p4config

# Made it to the end
exit 0