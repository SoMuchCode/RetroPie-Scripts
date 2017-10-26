#!/bin/sh

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

configfile=/etc/rc.local
# configfile=rc.locanew

basicXBOX=$(cat "$configfile")
RCTEMP=$(cat "$configfile")
XBD=$(cat "$configfile" | grep xboxdrv)
#################

defaultConfig="sudo /opt/retropie/supplementary/xboxdrv/bin/xboxdrv --daemon --detach --id 0 --led 2 --type xbox360 --deadzone 4400 --silent --trigger-as-button --alt-config /opt/retropie/configs/all/joyhelp/xboxdrv_4way.cfg --alt-config /opt/retropie/configs/all/joyhelp/xboxdrv_player1.cfg --alt-config /opt/retropie/configs/all/joyhelp/mouse.cfg --next-controller --id 1 --led 3 --type xbox360 --deadzone 4400 --silent --trigger-as-button --alt-config /opt/retropie/configs/all/joyhelp/xboxdrv_4way.cfg --alt-config /opt/retropie/configs/all/joyhelp/xboxdrv_player2.cfg --next-controller --controller-slot 2 --id 2 --led 4 --type xbox360 --deadzone 4400 --silent --trigger-as-button --alt-config /opt/retropie/configs/all/joyhelp/xboxdrv_4way.cfg --next-controller --controller-slot 3 --id 3 --led 5 --type xbox360 --deadzone 4400 --silent --trigger-as-button --alt-config /opt/retropie/configs/all/joyhelp/xboxdrv_4way.cfg --dbus disabled --detach-kernel-driver"

# want more output?
# change DBG to "1"
DBG="0"

if [ "$MODE" = "5" ] || [ "$MODE" = "6" ] || [ "$MODE" = "7" ] || [ "$MODE" = "8" ] || [ "$MODE" = "9" ]
then
	DBG="1"
fi
## DO some logging
if [ "$DBG" = "1" ]; then echo "rcfix: running - $(date)" >> $LOGFILE; fi
if [ "$DBG" = "1" ]; then echo "rcfix: Original Config:  $(cat $configfile)" >> $LOGFILE; fi

# Create temporary file - 
if [ "$XBD" ]; then			# we only want to do this if we need to...
	PREFIX=$(cat $configfile | grep xboxdrv)
	echo "$PREFIX" > $XBDRDIR/.tempdfile1
	cat $XBDRDIR/.tempdfile1 | head -n 1 > $XBDRDIR/.tempdfile2
	sed 's/\"//g' $XBDRDIR/.tempdfile2 > $XBDRDIR/.tempdfile3
	sed 's/\\//g' $XBDRDIR/.tempdfile3 > $XBDRDIR/.tempdfile4
	sed 's/xboxdrv.*/xboxdrv/g' $XBDRDIR/.tempdfile4 > $XBDRDIR/.launchoutfile		## This is the first line of the launch outfile, it may have sudo in it
	
else
	# if we want to make a default config - here is where we would put it
	# xboxdrv should make one when it is installed
	echo "$defaultConfig" > $XBDRDIR/.launchoutfile
	XBD="HELL YEAH"
	
fi
## Now we should have a New rc.local TAIL in .launchoutfile

# New rc.local HEAD
# remove newlines 
echo "$RCTEMP" > $XBDRDIR/.tempdfile1
tr -s '\n' ' ' < $XBDRDIR/.tempdfile1 > $XBDRDIR/.tempdfile2
tr -s '\r' ' ' < $XBDRDIR/.tempdfile2 > $XBDRDIR/.tempdfile3
sed 's/\"/ /g' $XBDRDIR/.tempdfile3 > $XBDRDIR/.tempdfile4
sed 's/\\/\\ /g' $XBDRDIR/.tempdfile4 > $XBDRDIR/.tempdfile3
sed 's/  / /g' $XBDRDIR/.tempdfile3 > $XBDRDIR/.tempdfile2


RCTEMP=$(cat "$XBDRDIR/.tempdfile2")			## RE_DEFINED RCTEMP!!!!
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
	
echo "$outfile" >> $XBDRDIR/.launchoutfile
tr -s '\n' ' ' < $XBDRDIR/.launchoutfile > $XBDRDIR/.tempdfile1
tr -s '\r' ' ' < $XBDRDIR/.tempdfile1 > $XBDRDIR/.tempdfile2
sed 's|\\|\\ \n|g' $XBDRDIR/.tempdfile2 > $XBDRDIR/.tempdfile3
sed 's|&|& \n|g' $XBDRDIR/.tempdfile3 > $XBDRDIR/.tempdfile4
sed 's|#||g' $XBDRDIR/.tempdfile4 > $XBDRDIR/.tempdfile2
sed 's|sleep 1|sleep 1 \n|g' $XBDRDIR/.tempdfile2 > $XBDRDIR/.tempdfile3
sed 's|sleep 2|sleep 2 \n|g' $XBDRDIR/.tempdfile3 > $XBDRDIR/.launchoutfile

## We should have a fairly sane config file now, no matter the style
cat "$XBDRDIR/.launchoutfile" > joyhelp-config.cfg

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
echo "$RCTEMP" > $XBDRDIR/.tempdfile1			## grab rc.local that is flat and should be split at word: xboxdrv
tr -s '\r' ' ' < $XBDRDIR/.tempdfile1 > $XBDRDIR/.tempdfile2
sed ':a;N;$!ba;s|\n| jjjjjCLMjjjjj |g' $XBDRDIR/.tempdfile2 > $XBDRDIR/.tempdfile3

RCTEMP=$(cat "$XBDRDIR/.tempdfile3")		# This is the original (full) flartened/custom delimited rc.local
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
echo "$outfile" > $XBDRDIR/.tempdfile1
sed 's|jjjjjCLMjjjjj exit 0|\n|g' $XBDRDIR/.tempdfile1 > $XBDRDIR/.tempdfile2
sed 's|jjjjjCLMjjjjj |\n|g' $XBDRDIR/.tempdfile2 > $XBDRDIR/.tempdfile3
sed 's|jjjjjCLMjjjjj|\n|g' $XBDRDIR/.tempdfile3 > $XBDRDIR/.tempdfile4

## works but kills too much whitespace
# CTEMP=$(cat -s "$XBDRDIR/.tempdfile4")
# echo "$CTEMP" > $XBDRDIR/.tempdfile2

# wow, sed can remove \n\n
sed 'N;/^\n$/D;P;D;' $XBDRDIR/.tempdfile4 > $XBDRDIR/.tempdfile2

sed 's|  | |g' $XBDRDIR/.tempdfile2 > $XBDRDIR/.tempdfile1
sed 's| #!/bin/sh|#!/bin/sh|g' $XBDRDIR/.tempdfile1 > $XBDRDIR/.rc-head

if [ "$JOYHELP" = "" ]; then			## hey we are NOT installed
	sudo cp $configfile "$configfile".bakup
	XXD=$(cat "$XBDRDIR/rcfix.dat")
	if [ "$DBG" = "1" ]; then echo "rcfix: Joyhelp not installed in rc.local; Install it now!" >> $LOGFILE; fi
	echo "$XXD"	>> $XBDRDIR/.rc-head
else									## We are installed, do an in-place update of script in rc.local
	XXD=$(cat "$XBDRDIR/rcfix.dat")		## we should flag this somewhere so we can do a full update
	echo "$XXD"	>> $XBDRDIR/.rc-head	## if needed...
	if [ "$DBG" = "1" ]; then echo "rcfix: Joyhelp already installed in rc.local; Update it now!" >> $LOGFILE; fi
	#####echo "updated"	>> $XBDRDIR/.rclocal-updated		## IDK what to do with this, but now it's flagged
fi
	echo "" > $XBDRDIR/.tempdfile2
	tr -s '\r' ' ' < $XBDRDIR/.launchoutfile >> $XBDRDIR/.tempdfile2
	sed ':a;N;$!ba;s|\n|jjjjjCLMjjjjj|g' $XBDRDIR/.tempdfile2 > $XBDRDIR/.tempdfile3	
	sed 's|jjjjjCLMjjjjj|\n#|g' $XBDRDIR/.tempdfile3 >> $XBDRDIR/.rc-head


# make sure we have an exit 0 at the end of new rc.local
exitOK=$(cat "$XBDRDIR/.rc-head" | grep "exit 0")
if [ "$exitOK" != "" ]; then
	echo "" >> $XBDRDIR/.rc-head
	echo "exit 0" >> $XBDRDIR/.rc-head
fi

sudo cp $XBDRDIR/.rc-head "$configfile"

sudo rm $XBDRDIR/.launchoutfile
sudo rm $XBDRDIR/.tempdfile4
sudo rm $XBDRDIR/.tempdfile3
sudo rm $XBDRDIR/.tempdfile2
sudo rm $XBDRDIR/.tempdfile1
sudo rm $XBDRDIR/.rc-head

#######################################

if [ "$DBG" = "1" ]; then echo "rcfix: running - $(date)" >> $LOGFILE; fi
if [ "$DBG" = "1" ]; then echo "rcfix: Original Config:  $(cat $configfile)" >> $LOGFILE; fi

## Now that we have fixed (hopefully) rc.local,
## we can make the config files...
$XBDRDIR/configfix.sh



# Made it to the end
exit 0