#!/bin/bash


# This script runs when RetroPie launches a game.
# If you are running xboxdrv NOT in demon mode
# you can add custom joytsick configs below and they 
# will be called by the xboxdrv driver when the game
# is launched.
#
# On game exit another script should
# unload the xboxdrv joystick driver
# and re-enable xpad or re-enable
# the original xboxdrv joystick config
# as long as it's not running as a daemon.

## TODO:
## Come up with a long/short or multiple-button config for my arcade stick (no select button)
		# start + LB = coin insert
		# start + RB = exit
## Finish multi controller stuff
		# we have # of controllers configured
		# match player to controller? by prod:vend? or name? or number? idk prolly unneeded


# The original script came from a RetroPie/xboxdrv tutorial at
# https://github.com/RetroPie/RetroPie-Setup/wiki/Universal-Controller-Calibration-&-Mapping-Using-xboxdrv
# Some bits from: https://retropie.org.uk/forum/topic/2861/guide-advanced-controller-mappings/380
# were also used to make this script.

#################

## Uncomment one or all of the following if you need to find some information about the emulator or roms
## Name of the emulator
echo $1 >> /dev/shm/runcommand.log

## Name of the software used for running the emulation
#echo $2 >> /dev/shm/runcommand.log

## Name of the rom
#echo $3 >> /dev/shm/runcommand.log

## Executed command line
#echo $4 >> /dev/shm/runcommand.log

## Get ROM name striping full path
rom="${3##*/}"

# important files and directories
CONFIGDIR=/opt/retropie/configs/all
JOYHELPDIR=$CONFIGDIR/joyhelp
DEFCFG=$JOYHELPDIR/joyhelp.cfg		# this is the control config file...
logfile=$JOYHELPDIR/joyhelp.log
configfile=$JOYHELPDIR/joyhelp-nodaemon.cfg	# this is the xboxdrv config file
basicXBOX=$(cat "$configfile")
# set default variables

# this should be the location of our individual game / system config file
CFGFILE=/opt/retropie/configs/$1/joyhelp.cfg
CFGFILEB=/opt/retropie/configs/ports/$1/joyhelp.cfg

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

# Read system specific config file
if [ -f "$CFGFILE" ]
then
  CFGCONTENT=$(cat $CFGFILE | sed -r '/[^=]+=[^=]+/!d' | sed -r 's/\s+=\s/=/g')
  eval "$CFGCONTENT"
  #echo "$CFGCONTENT"
elif [ -f "$CFGFILEB" ]
then
  CFGCONTENT=$(cat $CFGFILEB | sed -r '/[^=]+=[^=]+/!d' | sed -r 's/\s+=\s/=/g')
  eval "$CFGCONTENT"
else
	echo "$1 config file not found: $CFGFILE"  > /dev/null 2>&1
	if [ "$debug" -ge "1" ]; then echo "$1 config file not found: $CFGFILE" >> $logfile; fi
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
	calfilelocationrp="$xtemp > /dev/null 2>&1"
fi

if [ "$debug" -ge "1" ]; then echo "rcos: running - $(date)" >> $logfile; fi

}

do_drivers_loaded() {
	xpadloaded=$( lsmod | grep xpad )
	xboxdrvloaded=$( ps -A | grep xboxdrv )
}

do_test_config() {
echo "xpad $xpad"
echo "xboxdrv $xboxdrv"
echo "xbdctrlr $xbdctrlr"
echo "loadcalibrationfile $loadcalibrationfile"
echo "calfilelocation $calfilelocation"
echo "p1_profile $p1_profile"
echo "p2_profile $p2_profile"
echo "p3_profile $p3_profile"
echo "p4_profile $p4_profile"
echo "arcaderomlists $arcaderomlists"
echo "arcaderom4way $arcaderom4way"
echo "arcaderomdial $arcaderomdial"
echo "arcaderomtrackball $arcaderomtrackball"
echo "arcaderomanalog $arcaderomanalog"

# RetroPie specific variables
# used by runcommand-onend and rc.local
echo "xpadrp $xpadrp"
echo "xboxdrvrp $xboxdrvrp"
echo "loadcalibrationfilerp $loadcalibrationfilerp"
echo "calfilelocationrp $calfilelocationrp"

echo "$xpadloaded"
echo "$xboxdrvloaded"

}

# runcommand-onstart stuff
do_read_config
do_drivers_loaded

# Test for xboxdrv daemon mode
if [ "$xboxdrvrp" = 3 ]; then
	# Load calibration file??
	if [ "$loadcalibrationfile" = 1 ]; then
		if [ -f "$calfilelocation" ]; then
		$calfilelocation" > /dev/null 2>&1"
		fi
	fi
	if [ "$xpadloaded" ] && [ "$xpad" = 0 ]; then
		# kill xpad driver
		eval $xpadkill
	fi	
	if [ "$debug" -ge "1" ]; then echo "rcos: Daemon mode - exiting" >> $logfile; fi
	exit 0
fi

# if we made it here, we are NOT a daemon
if [ "$debug" -ge "1" ]; then echo "rcos: passed tests" >> $logfile; fi
if [ "$debug" -ge "1" ]; then echo "rcos: not a daemon" >> $logfile; fi

if [ "$debug" -ge "2" ]; then 
echo "rcos: start: lsmod" >> $logfile
lsmod >> $logfile
fi


if [ "$xpadloaded" ] && [ "$xpad" = 0 ]; then
	# kill xpad driver
	eval $xpadkill
	if [ "$debug" -ge "1" ]; then echo "rcos: xpad killed" >> $logfile; fi
fi

if [ "$xboxdrvloaded" ]; then
	# kill xboxdrv driver no matter what, we will launch it later with (possible) custom config
	eval $xboxkill
	if [ "$debug" -ge "1" ]; then echo "rcos: xboxdrv killed" >> $logfile; fi
fi

if [ "$xpadrp" = 0 ] && [ "$xpad" = 1 ]; then
	# start xpad driver
	sudo modprobe xpad dpad_to_buttons=1 triggers_to_buttons=1		# required to reconnect to xpad
	if [ "$debug" -ge "1" ]; then echo "rcos: xpad loaded" >> $logfile; fi
fi

if [ "$xpadloaded" ] && [ "$xpad" = 1 ]; then
	if [ "$debug" -ge "1" ]; then echo "rcos: xpad to xpad - nothing to do, exiting..." >> $logfile; fi
	exit 0
fi

# so we don't want to hardcode the command into the launch file...
if [ "$sudoForced" = 1 ]; then
	launchPrefix="sudo "$(cat "$JOYHELPDIR/.scripts/.xbd_prefix")
	if [ "$debug" -ge "1" ]; then echo "rcos: sudo forced" >> $logfile; fi
else
	launchPrefix=$(cat "$JOYHELPDIR/.scripts/.xbd_prefix")
fi
launchSuffix=$(cat "$JOYHELPDIR/.scripts/.xbd_suffix")
if ! [ "$p1_lconfig" ]; then
	p1_lconfig=$(cat "$JOYHELPDIR/.scripts/.xbd_p1config")
fi
if ! [ "$p2_lconfig" ]; then
	p2_lconfig=$(cat "$JOYHELPDIR/.scripts/.xbd_p2config")
fi
if ! [ "$p3_lconfig" ]; then
	p3_lconfig=$(cat "$JOYHELPDIR/.scripts/.xbd_p3config")
fi
if ! [ "$p4_lconfig" ]; then
	p4_lconfig=$(cat "$JOYHELPDIR/.scripts/.xbd_p4config")
fi
# p1_lconfig=$(cat "$JOYHELPDIR/.scripts/.xbd_p1config")
# p2_lconfig=$(cat "$JOYHELPDIR/.scripts/.xbd_p2config")
# p3_lconfig=$(cat "$JOYHELPDIR/.scripts/.xbd_p3config")
# p4_lconfig=$(cat "$JOYHELPDIR/.scripts/.xbd_p4config")

# count controller config files
controllers=4
if [ "$p4_lconfig" = "" ]; then
	controllers=$((controllers-1))
fi
if [ "$p3_lconfig" = "" ]; then
	controllers=$((controllers-1))
fi
if [ "$p2_lconfig" = "" ]; then
	controllers=$((controllers-1))
fi
if [ "$p1_lconfig" = "" ]; then
	controllers=$((controllers-1))
fi
if [ "$debug" -ge "1" ]; then echo "rcos: Configured Controllers = $controllers" >> $logfile; fi
# How did this happen??? 0 controllers connected
# Log but don't exit
if [ "$controllers" = "0" ] && [ "$debug" -ge "1" ]; then echo "rcos: This doesn't sound right..." >> $logfile; fi


## see if we need to add --detach-kernel-driver to launch command
dteatch=""
dteatch=$( echo "$launchSuffix" | grep "kernel" )

if ! [ "$dteatch" ]; then
	echo "made it here"
	if [ "$xpad" = 1 ] && [ "$xboxdrv" = 1 ]; then
		# add --detach kernel driver to command since we are not killing xpad
		xtemp=$p1_profile" --detach-kernel-driver"
		p1_profile=$xtemp
		xtemp=$p2_profile" --detach-kernel-driver"
		p2_profile=$xtemp
		xtemp=$p3_profile" --detach-kernel-driver"
		p3_profile=$xtemp
		xtemp=$p4_profile" --detach-kernel-driver"
		p4_profile=$xtemp
	fi
fi

#################

### Set variables for your joypad and emulator
### Basic Configuraions - Standard controller mappings

portsXBOX="/opt/retropie/supplementary/xboxdrv/bin/xboxdrv \
	--silent \
	--detach-kernel-driver \
	--force-feedback \
	--deadzone-trigger 15% \
	--deadzone 4000 \
	--trigger-as-button \
	--evdev-absmap ABS_X=x1,ABS_Y=y1,ABS_RX=x2,ABS_RY=y2,ABS_HAT0X=dpad_x,ABS_HAT0Y=dpad_y \
	--evdev-keymap BTN_TL2=lt,BTN_TR2=rt  \
	--evdev-keymap BTN_SOUTH=a,BTN_EAST=b,BTN_WEST=x,BTN_NORTH=y,BTN_TL=lb,BTN_TR=rb,BTN_THUMBL=tl,BTN_THUMBR=tr,BTN_MODE=guide,BTN_SELECT=back,BTN_START=start"
	
testXBOX="/opt/retropie/supplementary/xboxdrv/bin/xboxdrv \
	--silent \
	--detach-kernel-driver \
	--force-feedback \
	--deadzone-trigger 15% \
	--deadzone 4000 \
	--mimic-xpad \
	--evdev-absmap ABS_X=x1,ABS_Y=y1,ABS_RX=x2,ABS_RY=y2,ABS_HAT0X=dpad_x,ABS_HAT0Y=dpad_y \
	--evdev-keymap BTN_TL2=lt,BTN_TR2=rt  \
	--evdev-keymap BTN_SOUTH=a,BTN_EAST=b,BTN_WEST=x,BTN_NORTH=y,BTN_TL=lb,BTN_TR=rb,BTN_THUMBL=tl,BTN_THUMBR=tr,BTN_MODE=guide,BTN_SELECT=back,BTN_START=start"
	
basicPS3="/opt/retropie/supplementary/xboxdrv/bin/xboxdrv >/dev/null \
	--silent \
	--detach-kernel-driver \
	--force-feedback \
	--mimic-xpad \
	--dpad-as-button \
	--trigger-as-button \
	--evdev-absmap ABS_X=x1,ABS_Y=y1,ABS_Z=x2,ABS_RX=y2 \
	--evdev-keymap KEY_#302=a,KEY_#301=b,BTN_DEAD=x,KEY_#300=y,BTN_THUMB=tl,BTN_THUMB2=tr,BTN_BASE5=lb,BTN_BASE6=rb,BTN_BASE3=lt,BTN_BASE4=rt,BTN_TRIGGER=back,BTN_TOP=start,BTN_SOUTH=guide,BTN_TOP2=du,BTN_PINKIE=dr,BTN_BASE=dd,BTN_BASE2=dl
	--calibration x1=-32767:0:32767,y1=-32767:0:32767,x2=-32767:0:32767,y2=-32767:0:32767"

### Extended Configurations
### Specific emulator configuration or any other parameters you will need only for some emulators
scummVM="--axismap Y1=Y1,Y2=Y2 \
	--ui-axismap x1=REL_X:10,y1=REL_Y:10 \
	--ui-buttonmap a=BTN_LEFT,b=BTN_RIGHT,start=KEY_F5,back=KEY_ESC \
	--ui-buttonmap guide=void,x=void,y=void,lb=void,rb=void,tl=void,tr=void,lt=void,rt=void,back=void \
	--ui-axismap x2=void"

amiga="--axismap -Y1=Y1,-Y2=Y2 \
	--ui-axismap x2=REL_X:1,y2=REL_Y:1 \
	--ui-axismap x1=KEY_LEFT:KEY_RIGHT,y1=KEY_DOWN:KEY_UP \
	--ui-buttonmap du=KEY_UP,dd=KEY_DOWN,dl=KEY_LEFT,dr=KEY_RIGHT \
	--ui-buttonmap lt=BTN_LEFT,rt=BTN_RIGHT,start=KEY_ESC,back=KEY_LEFTCTRL,y=KEY_SPACE,a=KEY_LEFTCTRL,b=KEY_LEFTALT,x=KEY_LEFTSHIFT \
	--ui-buttonmap guide=void,tl=void,lt=void,rt=void,back=void \
	--ui-axismap x2=void"

####### In Testing --------------------
## This is from another config; fix to work with this script.
### Player 1 and 2 joystick settings for Amiga games - only change is to the axes which have been swapped; not mapped to UAE4ARM's default keyboard settings
amigaplayer1="--device-name "Amiga_Joystick_Player_1_xboxdrv" \
	--evdev /dev/input/by-path/platform-3f980000.usb-usb-0:1.3.3:1.0-event-joystick \
	--evdev-absmap ABS_X=y1,ABS_Y=x1 \
	--evdev-keymap BTN_TRIGGER=x,BTN_THUMB=y,BTN_THUMB2=a,BTN_PINKIE=b,BTN_BASE3=back,BTN_BASE6=start"

amigaplayer2="--device-name "Amiga_Joystick_Player_2_xboxdrv" \
	--evdev /dev/input/by-path/platform-3f980000.usb-usb-0:1.3.1:1.0-event-joystick \
	--evdev-absmap ABS_X=y1,ABS_Y=x1 \
	--evdev-keymap BTN_TRIGGER=y,BTN_THUMB=a,BTN_THUMB2=back,BTN_PINKIE=x,BTN_TOP=b,BTN_TOP2=start"

## Unused
wingCommander34="--dpad-as-button \
--ui-axismap x1=KEY_LEFT:KEY_RIGHT,y1=KEY_UP:KEY_DOWN,x2=KEY_INSERT:KEY_DELETE,y2=KEY_EQUAL:KEY_MINUS \
--ui-buttonmap tl=KEY_RIGHTSHIFT,back=KEY_GRAVE,start=KEY_A,y=KEY_Y,x=KEY_0,b=KEY_E,a=KEY_L,rb=KEY_T,lb=KEY_R,rt=KEY_SPACE,lt=KEY_ENTER,du=KEY_G,dd=KEY_M,dl=KEY_F,dr=KEY_B"
####### END SECTION --------------------

# Four way axis restrictor for games like Pacman
fourway="--four-way-restrictor"

#any custom dial configs
dial="--four-way-restrictor"

#any custom trackball configs
trackball=""

#any custom analog controller configs
analog=""

# invert d-pad up/down
invert="--ui-buttonmap du=KEY_DOWN,dd=KEY_UP"

# invert left stick up/down
invert_analog_y1="--axismap -Y1=Y1"

# invert right stick up/down
invert_analog_y2="--axismap -Y2=Y2"

# Square axis for old (DOS) games
sq_axis="--square-axis"

# Axis Limiter if above doesn't work
lim_axis="--square-axis --calibration Y1=-22936:0:22936"

# Custom player 1 options
#arcade_p1="--mimic-xpad
arcade_p1=""

## Custom player 2 options
#arcade_p2="--mimic-xpad
arcade_p2=""

## Custom player 3 options
#arcade_p3="--mimic-xpad-wireless"
arcade_p3=""

## Custom player 4 options
#arcade_p4="--mimic-xpad-wireless"
arcade_p4=""

### I generated most of these lists with Romlister
## 4-way Games
My4wayList=""005.zip"|"600.zip"|"8bpm.zip"|"abscam.zip"|"alibaba.zip"|"alibabab.zip"|"alphaho.zip"|"amidar.zip"|"amidar1.zip"|"amidarb.zip"|"amidaro.zip"|"amidars.zip"|"amidaru.zip"|"amigo.zip"|"anteater.zip"|"anteaterg.zip"|"anteatergg.zip"|"anteateruk.zip"|"armorcar.zip"|"armorcar2.zip"|"armwrest.zip"|"ashnojoe.zip"|"atetris.zip"|"atetrisa.zip"|"atetrisb.zip"|"atetrisb2.zip"|"atetrisb3.zip"|"atetrisc.zip"|"atetrisc2.zip"|"babypac.zip"|"babypac2.zip"|"banbam.zip"|"beastf.zip"|"bestri.zip"|"bigbucks.zip"|"bigkong.zip"|"birdiy.zip"|"blasto.zip"|"blkbustr.zip"|"blockade.zip"|"blockhl.zip"|"brdrlinb.zip"|"brdrline.zip"|"brdrlinet.zip"|"brdrlins.zip"|"brixian.zip"|"btime.zip"|"btime2.zip"|"btime3.zip"|"btimem.zip"|"bucaner.zip"|"calorie.zip"|"calorieb.zip"|"cannonb.zip"|"cannonb2.zip"|"cannonb3.zip"|"cannonbp.zip"|"car2.zip"|"carhntds.zip"|"carjmbre.zip"|"chameleo.zip"|"ckong.zip"|"ckongalc.zip"|"ckongdks.zip"|"ckongg.zip"|"ckonggx.zip"|"ckongmc.zip"|"ckongo.zip"|"ckongpt2.zip"|"ckongpt2a.zip"|"ckongpt2b.zip"|"ckongpt2j.zip"|"ckongpt2jeu.zip"|"ckongs.zip"|"comotion.zip"|"cookrace.zip"|"cottong.zip"|"crash.zip"|"crazyblk.zip"|"crockman.zip"|"crospang.zip"|"crush.zip"|"crush2.zip"|"crush3.zip"|"crush4.zip"|"crushbl.zip"|"crushbl2.zip"|"crushbl3.zip"|"crushrlf.zip"|"crushs.zip"|"ctrpllrp.zip"|"dai3wksi.zip"|"devilfsg.zip"|"diamond.zip"|"digdug.zip"|"digdug1.zip"|"digdug2.zip"|"digdug2o.zip"|"digdugat.zip"|"digdugat1.zip"|"digger.zip"|"digsid.zip"|"disco.zip"|"discof.zip"|"dking.zip"|"dkingjr.zip"|"dkong.zip"|"dkong3.zip"|"dkong3b.zip"|"dkong3j.zip"|"dkongf.zip"|"dkonghrd.zip"|"dkongj.zip"|"dkongjnrj.zip"|"dkongjo.zip"|"dkongjo1.zip"|"dkongjr.zip"|"dkongjrb.zip"|"dkongjre.zip"|"dkongjrj.zip"|"dkongjrm.zip"|"dkongjrpb.zip"|"dkongo.zip"|"dkongpe.zip"|"dkongx.zip"|"dkongx11.zip"|"docastle.zip"|"docastle2.zip"|"docastleo.zip"|"dodgem.zip"|"domino.zip"|"dominos.zip"|"dominos4.zip"|"dommy.zip"|"dorodon.zip"|"dorodon2.zip"|"dorunrun.zip"|"dorunrun2.zip"|"dorunrunc.zip"|"dorunrunca.zip"|"douni.zip"|"drakton.zip"|"dremshpr.zip"|"drgnbstr.zip"|"drktnjr.zip"|"drmicro.zip"|"drtomy.zip"|"dzigzag.zip"|"eggor.zip"|"eggs.zip"|"elecyoyo.zip"|"elecyoyo2.zip"|"evilston.zip"|"eyes.zip"|"eyes2.zip"|"eyesb.zip"|"eyeszacb.zip"|"fantasia.zip"|"fantasiaa.zip"|"fantasiab.zip"|"fantasian.zip"|"fantsia2.zip"|"fantsia2a.zip"|"fantsia2n.zip"|"fantsy95.zip"|"filetto.zip"|"frogf.zip"|"frogg.zip"|"frogger.zip"|"froggermc.zip"|"froggers.zip"|"froggers1.zip"|"froggers2.zip"|"froggers3.zip"|"froggrs.zip"|"funquiz.zip"|"galpanic.zip"|"galpanica.zip"|"galsnew.zip"|"galsnewa.zip"|"galsnewj.zip"|"galsnewk.zip"|"ghostmun.zip"|"gmgalax.zip"|"gorkans.zip"|"gundealr.zip"|"gundealra.zip"|"gundealrbl.zip"|"gundealrt.zip"|"gutangtn.zip"|"guzzler.zip"|"guzzlers.zip"|"hangly.zip"|"hangly2.zip"|"hangly3.zip"|"hardhat.zip"|"headon.zip"|"headon1.zip"|"headon2.zip"|"headonmz.zip"|"headons.zip"|"heiankyo.zip"|"heuksun.zip"|"hexa.zip"|"higemaru.zip"|"hocrash.zip"|"hustle.zip"|"invho2.zip"|"jackler.zip"|"jjack.zip"|"jollyjgr.zip"|"joyman.zip"|"jrking.zip"|"jrpacman.zip"|"jrpacmanf.zip"|"jrpacmbl.zip"|"jungler.zip"|"junglers.zip"|"kicker.zip"|"kickridr.zip"|"kikcubic.zip"|"kikcubicb.zip"|"knockout.zip"|"knockoutb.zip"|"korosuke.zip"|"ladybgb2.zip"|"ladybug.zip"|"ladybugb.zip"|"ladybugg.zip"|"lasso.zip"|"lnc.zip"|"locoboot.zip"|"locomotn.zip"|"lupin3.zip"|"lupin3a.zip"|"maketrax.zip"|"maketrxb.zip"|"mbrush.zip"|"merlinmm.zip"|"microtan.zip"|"mikie.zip"|"mikiehs.zip"|"mikiej.zip"|"mineswpr.zip"|"mineswpr4.zip"|"missmw96.zip"|"missw96.zip"|"missw96a.zip"|"missw96b.zip"|"missw96c.zip"|"mmonkey.zip"|"momoko.zip"|"monkeyd.zip"|"monsterb.zip"|"monsterb2.zip"|"mrdo.zip"|"mrdofix.zip"|"mrdot.zip"|"mrdoy.zip"|"mrdu.zip"|"mrflea.zip"|"mrjong.zip"|"mrlo.zip"|"mrtnt.zip"|"mschamp.zip"|"mschamps.zip"|"msheartb.zip"|"msjiken.zip"|"mspacii.zip"|"mspacii2.zip"|"mspacmab.zip"|"mspacman.zip"|"mspacmanbcc.zip"|"mspacmanbg.zip"|"mspacmanbgd.zip"|"mspacmanblt.zip"|"mspacmancr.zip"|"mspacmat.zip"|"mspacmbe.zip"|"mspacmnf.zip"|"mspacpls.zip"|"mystston.zip"|"myststono.zip"|"myststonoi.zip"|"natodef.zip"|"natodefa.zip"|"naughtyb.zip"|"naughtyba.zip"|"naughtybc.zip"|"netwars.zip"|"newfant.zip"|"newfanta.zip"|"newpuc2.zip"|"newpuc2b.zip"|"newpuckx.zip"|"nmouse.zip"|"nmouseb.zip"|"nrallyx.zip"|"nrallyxb.zip"|"ohpaipee.zip"|"olibochu.zip"|"pacgal.zip"|"pacheart.zip"|"pacman.zip"|"pacmanbl.zip"|"pacmanbla.zip"|"pacmanf.zip"|"pacmanjpm.zip"|"pacmansp.zip"|"pacmod.zip"|"pacnchmp.zip"|"pacnpal.zip"|"pacnpal2.zip"|"pacplus.zip"|"pacuman.zip"|"paintrlr.zip"|"pairsnb.zip"|"pairsten.zip"|"panic.zip"|"panic2.zip"|"panic3.zip"|"panicger.zip"|"panich.zip"|"panzer.zip"|"pengo.zip"|"pengo2.zip"|"pengo2u.zip"|"pengo3u.zip"|"pengo4.zip"|"pengob.zip"|"pengojpm.zip"|"pengopac.zip"|"penta.zip"|"pepper2.zip"|"pepper27.zip"|"perestro.zip"|"perestrof.zip"|"pettanp.zip"|"phantom.zip"|"phantoma.zip"|"photof.zip"|"pignewt.zip"|"pignewta.zip"|"piranha.zip"|"piranhah.zip"|"piranhao.zip"|"pitnrun.zip"|"pitnruna.zip"|"popeye.zip"|"popeyebl.zip"|"popeyef.zip"|"popeyeman.zip"|"popeyeu.zip"|"popflame.zip"|"popflamea.zip"|"popflameb.zip"|"popflamen.zip"|"portrait.zip"|"portraita.zip"|"protennb.zip"|"puckman.zip"|"puckmanb.zip"|"puckmanf.zip"|"puckmanh.zip"|"puckmod.zip"|"pulsar.zip"|"qix.zip"|"qix2.zip"|"qixa.zip"|"qixb.zip"|"qixo.zip"|"quaak.zip"|"quarth.zip"|"raiders5.zip"|"raiders5t.zip"|"rallys.zip"|"rallysa.zip"|"rallyx.zip"|"rallyxa.zip"|"rallyxm.zip"|"rallyxmr.zip"|"rbtapper.zip"|"redbaron.zip"|"redbarona.zip"|"robby.zip"|"rockduck.zip"|"rocktrv2.zip"|"route16.zip"|"route16a.zip"|"route16bl.zip"|"route16c.zip"|"routex.zip"|"rthunder.zip"|"rthunder0.zip"|"rthunder1.zip"|"rthunder2.zip"|"rthundera.zip"|"rugrats.zip"|"samurai.zip"|"savanna.zip"|"scessjoe.zip"|"schaser.zip"|"schasera.zip"|"schaserb.zip"|"schaserc.zip"|"schasercv.zip"|"schaserm.zip"|"scregg.zip"|"sderby.zip"|"shaolinb.zip"|"shaolins.zip"|"sidetrac.zip"|"sindbadm.zip"|"smash.zip"|"smissw.zip"|"spectar.zip"|"spectar1.zip"|"spiero.zip"|"sprglbpg.zip"|"sprglobp.zip"|"sqix.zip"|"sqixb1.zip"|"sqixb2.zip"|"sqixr1.zip"|"sqixu.zip"|"sraider.zip"|"sspacaho.zip"|"starrkr.zip"|"startrks.zip"|"streakng.zip"|"streaknga.zip"|"supcrash.zip"|"superabc.zip"|"superabco.zip"|"superpac.zip"|"superpacm.zip"|"supmodel.zip"|"sutapper.zip"|"tactcian.zip"|"tactcian2.zip"|"tankbatt.zip"|"tankbattb.zip"|"tapper.zip"|"tappera.zip"|"targ.zip"|"targc.zip"|"taxidriv.zip"|"telmahjn.zip"|"theglobp.zip"|"thief.zip"|"timber.zip"|"timelimt.zip"|"todruaga.zip"|"todruagao.zip"|"todruagas.zip"|"togenkyo.zip"|"tomahawk.zip"|"tomahawk1.zip"|"toucheme.zip"|"touchemea.zip"|"toypop.zip"|"tranqgun.zip"|"triplep.zip"|"triplepa.zip"|"tryout.zip"|"tsamurai.zip"|"tsamurai2.zip"|"tsamuraih.zip"|"turpin.zip"|"turtles.zip"|"tvgame.zip"|"vanvan.zip"|"vanvanb.zip"|"vanvank.zip"|"warpwarp.zip"|"warpwarpr.zip"|"warpwarpr2.zip"|"wiping.zip"|"wiseguy.zip"|"wndrmomo.zip"|"woodpeca.zip"|"woodpeck.zip"|"wownfant.zip"|"wwjgtin.zip"|"yamyam.zip"|"yamyamk.zip"|"yankeedo.zip"|"zerozone.zip"|"zigzagb.zip"|"zigzagb2.zip"|"zookeep.zip"|"zookeep2.zip"|"zookeep3.zip""

## FBA 4-way Games (very incomplete list)
RestrictedArcadeGamesFBA=""amidar.zip"|"atetris.zip"|"alibaba.zip"|"anteater.zip"|"afighter.zip"|"btime.zip"|"commando.zip"|"congo.zip"|"ckongs.zip"|"eyes.zip"|"frogger.zip"|"kungfum.zip"|"mrdo.zip"|"mspacmat.zip"|"ozmawars.zip"|"pacman.zip"|"pacheart.zip"|"punchout.zip"|"qbert.zip"|"qix.zip"|"shollow.zip"|"supbtime.zip"|"mspacpls.zip"|"mspacman.zip"|"dkong.zip"|"dkongjr.zip"|"dkong3.zip""

## Trackball Games
TrackballGames=""horshoes.zip"|"amerdart.zip"|"amerdart2.zip"|"amerdart3.zip"|"arcadecl.zip"|"argusg.zip"|"abaseb.zip"|"abaseb2.zip"|"atarifb4.zip"|"atarifb1.zip"|"atarifb.zip"|"atarifb2.zip"|"soccer.zip"|"ataxxe.zip"|"ataxxj.zip"|"ataxx.zip"|"ataxxa.zip"|"bsktball.zip"|"beezer.zip"|"beezer1.zip"|"bigevglfj.zip"|"bigevglf.zip"|"bking.zip"|"bking2.zip"|"bking3.zip"|"bootcamp.zip"|"bootcampa.zip"|"bowler.zip"|"bowlrama.zip"|"bullsdrt.zip"|"cabalus.zip"|"cabalus2.zip"|"capbowl.zip"|"capbowl2.zip"|"capbowl3.zip"|"capbowl4.zip"|"champbwl.zip"|"cloud9.zip"|"combatscj.zip"|"combatsct.zip"|"coolpool.zip"|"clbowl.zip"|"countryc.zip"|"ccastles1.zip"|"ccastles2.zip"|"ccastles3.zip"|"ccastlesf.zip"|"ccastlesg.zip"|"ccastlesp.zip"|"ccastles.zip"|"cubeqst.zip"|"cubeqsta.zip"|"dangerz.zip"|"demndrgn.zip"|"dunkshoto.zip"|"dunkshota.zip"|"dunkshot.zip"|"dynobop.zip"|"exctleagd.zip"|"exctleag.zip"|"ebases.zip"|"firebeas.zip"|"fiveside.zip"|"galgame2.zip"|"gimeabrk.zip"|"gghost.zip"|"gt2k.zip"|"gt2kp100.zip"|"gt2ks100.zip"|"gt2kt500.zip"|"gt3dv14.zip"|"gt3dv15.zip"|"gt3dv16.zip"|"gt3dv17.zip"|"gt3dv18.zip"|"gt3dl191.zip"|"gt3dl192.zip"|"gt3ds192.zip"|"gt3d.zip"|"gt3dl19.zip"|"gt3dt211.zip"|"gt3dt231.zip"|"gt97v120.zip"|"gt97v121.zip"|"gt97s121.zip"|"gt97v122.zip"|"gt97.zip"|"gt97t240.zip"|"gt97t243.zip"|"gt98v100.zip"|"gt98s100.zip"|"gt98.zip"|"gt98t303.zip"|"gt99.zip"|"gt99s100.zip"|"gt99t400.zip"|"gtclassc.zip"|"gtclasscp.zip"|"gtclasscs.zip"|"gtdiamond.zip"|"gtgt1.zip"|"gtgt.zip"|"gtg2t.zip"|"gtg2.zip"|"gtroyal.zip"|"gtsupreme.zip"|"gridiron.zip"|"gridlee.zip"|"lemmings.zip"|"liberatr.zip"|"liberatr2.zip"|"macxl.zip"|"magworm.zip"|"mjleague.zip"|"marble.zip"|"marble2.zip"|"marble3.zip"|"marble4.zip"|"marble5.zip"|"marinedt.zip"|"mcommand.zip"|"minigolf2.zip"|"minigolf.zip"|"missile1.zip"|"missile2.zip"|"missile.zip"|"poundforj.zip"|"poundforu.zip"|"poundfor.zip"|"quantump.zip"|"quantum1.zip"|"quantum.zip"|"rampart.zip"|"reactor.zip"|"sonicp.zip"|"sonic.zip"|"shootbul.zip"|"shuffle.zip"|"shufshot137.zip"|"shufshot139.zip"|"shufshot.zip"|"shuuz.zip"|"slikshot16.zip"|"slikshot17.zip"|"slikshot.zip"|"slither.zip"|"slithera.zip"|"snakjack.zip"|"spiker.zip"|"spiker2.zip"|"spiker3.zip"|"stratab1.zip"|"stratab.zip"|"sbowling.zip"|"suprleag.zip"|"suprmatk.zip"|"suprmatkd.zip"|"sstrike.zip"|"syvalion.zip"|"syvalionp.zip"|"teedoff.zip"|"irrmaze.zip"|"trisport.zip"|"usclssic.zip"|"viper.zip"|"wcbowl11.zip"|"wcbowl12.zip"|"wcbowl13.zip"|"wcbowl13j.zip"|"wcbowl14.zip"|"wcbowl15.zip"|"wcbowl16.zip"|"wcbowl161.zip"|"wcbowl165.zip"|"wcbowl.zip"|"wcbowldx.zip"|"wcbowl140.zip"|"xtheball.zip""

## Analog Games
AnalogGames=""aburner.zip"|"aburner2.zip"|"aburner2g.zip"|"eprom.zip"|"eprom2.zip"|"foodfc.zip"|"foodf1.zip"|"foodf2.zip"|"foodf.zip"|"gforce2.zip"|"gforce2j.zip"|"gforce2ja.zip"|"gforce2sd.zip"|"glocu.zip"|"gloc.zip"|"glocr360.zip"|"irobot.zip"|"roadrunn1.zip"|"roadrunn2.zip"|"roadrunn.zip"|"sharrier1.zip"|"sharrier.zip"|"tailg.zip"|"thndrbld1.zip"|"thndrbldd.zip"|"thndrbld.zip"|"tunhunt.zip"|"tunhuntc.zip""

## Dial / Spinner Games
DialGames=""720gr1.zip"|"720g.zip"|"720r1.zip"|"720r2.zip"|"720r3.zip"|"720.zip"|"alphaone.zip"|"alphaonea.zip"|"arknoid2b.zip"|"arknoid2j.zip"|"arknoid2u.zip"|"arknoid2.zip"|"arkgcbl.zip"|"arkgcbla.zip"|"ark1ball.zip"|"arkanoidjbl.zip"|"arkanoidjbl2.zip"|"arkangc.zip"|"arkangc2.zip"|"arkanoidja.zip"|"arkanoidj.zip"|"arkanoidjb.zip"|"arkatayt.zip"|"arktayt2.zip"|"arkanoidu.zip"|"arkanoiduo.zip"|"arkanoid.zip"|"armchmp2o.zip"|"armchmp2.zip"|"mgolf.zip"|"bm1stmix.zip"|"bm2ndmxa.zip"|"bm2ndmix.zip"|"bm3rdmix.zip"|"bm4thmix.zip"|"bm5thmix.zip"|"bm6thmix.zip"|"bm7thmix.zip"|"bmclubmx.zip"|"bmcompmx.zip"|"bmcompm2.zip"|"bmcorerm.zip"|"bmdct.zip"|"bmfinal.zip"|"blstroidg.zip"|"blstroid2.zip"|"blstroid3.zip"|"blstroid.zip"|"blstroidh.zip"|"arkblock.zip"|"arkbloc2.zip"|"arkbloc3.zip"|"block2.zip"|"blockbl.zip"|"blockj.zip"|"blockr2.zip"|"blockgalb.zip"|"blockgal.zip"|"boxingb.zip"|"brkblast.zip"|"cameltryj.zip"|"cameltryau.zip"|"cameltry.zip"|"cameltrya.zip"|"cerberus.zip"|"cchasm.zip"|"cchasm1.zip"|"darkplnt.zip"|"deltrace.zip"|"demoderb.zip"|"demoderbc.zip"|"demoderm.zip"|"dominob.zip"|"dominobv2.zip"|"embargo.zip"|"gigasb.zip"|"gigasm2b.zip"|"grudge.zip"|"spinkick.zip"|"hmcompmx.zip"|"hmcompm2.zip"|"jpopnics.zip"|"kickc.zip"|"kick.zip"|"kickman.zip"|"jongbou.zip"|"mjdialq2.zip"|"mjdialq2a.zip"|"mhavocp.zip"|"mhavocrv.zip"|"mhavoc2.zip"|"mhavoc.zip"|"moonwarp.zip"|"moonwar.zip"|"moonwara.zip"|"pokermon.zip"|"oigas.zip"|"omegrace.zip"|"omegrace2.zip"|"paddle2.zip"|"plumppop.zip"|"quester.zip"|"questers.zip"|"racingbj.zip"|"racingb.zip"|"razmataz.zip"|"ridleofp.zip"|"scudhamm.zip"|"solvalou.zip"|"sprint4.zip"|"sprint4a.zip"|"sprint8.zip"|"sprint8a.zip"|"startrek.zip"|"starbladj.zip"|"starblad.zip"|"stocker.zip"|"subs.zip"|"sfkick.zip"|"sfkicka.zip"|"tacscan.zip"|"teetert.zip"|"tempest1.zip"|"tempest1r.zip"|"tempest2.zip"|"tempest3.zip"|"tempest.zip"|"temptube.zip"|"arkatour.zip"|"twinsqua.zip"|"twotigerc.zip"|"victorba.zip"|"victory.zip"|"hotsmash.zip"|"wallc.zip"|"wallca.zip"|"wfortune.zip"|"wfortunea.zip"|"wheelrun.zip"|"wink.zip"|"winka.zip"|"winrun.zip"|"winrun91.zip"|"winrungp.zip"|"wolfpack.zip"|"zektor.zip""
####### END SECTION --------------------

# ##### UNUSED (From another config file) ---------
# ### LR-MAME2003 - LANDSCAPE MODE
# ### Settings for lr-mame2003 Arcade games in landscape mode - joysticks emulating virtual keyboards
# ### The joystick buttons have been mapped to the emulator's default keys. In lr-mame 2003 in game, press TAB to determine default keys.
# ### Player 1's default keys are: Buttons 1-4 (LCTRL, LALT, SPACE, LSHIFT), Start (1), Coin (5), Movement (Arrow keys)
# ### Player 2's default keys are: Buttons 1-4 (a, s, q, w), Start (2), Coin (6), Movement (g, d, r, f)
# ### For Joystick 1 (Player 1), Buttons 1 to 4 are for fire and jump and so on.  Button 5 will start Player 1; Button 6 will start Player 2; Holding Button 5 and pressing Button 6 together will exit emulator in line with Retroarch hotkey
# ### For Joystick 2 (Player 2), Buttons 1 to 4 are for fire and jump and so on.  Button 5 will start Player 2; Button 6 does nothing; Holding Button 5 and pressing Button 6 together will exit emulator in line with Retroarch hotkey
# #joy1keys="--ui-axismap X1=KEY_LEFT:KEY_RIGHT,Y1=KEY_UP:KEY_DOWN \
	# --ui-buttonmap a=KEY_LEFTCTRL,b=KEY_LEFTALT,x=KEY_SPACE,y=KEY_LEFTSHIFT,back=KEY_5+KEY_1,start=KEY_6+KEY_2,back+start=KEY_SPACE+KEY_ESC"

# #joy2keys="--ui-axismap X1=KEY_D:KEY_G,Y1=KEY_R:KEY_F \
	# --ui-buttonmap a=KEY_A,b=KEY_S,x=KEY_Q,y=KEY_W,back=KEY_6+KEY_2,start=KEY_UNKNOWN,back+start=KEY_SPACE+KEY_ESC"

# ### LR-MAME2003 - PORTRAIT MODE
# ### Settings for lr-mame2003 Arcade games in folder 'Arcade-Vertical' in portrait/cocktail mode - joysticks emulating virtual keyboards
# ### The joystick buttons have been mapped to the emulator's default keys. In lr-mame 2003 in game, press TAB to determine default keys.
# ### Player 1's default keys are: Buttons 1-4 (LCTRL, LALT, SPACE, LSHIFT), Start (1), Coin (5), Movement (Arrow keys)
# ### Player 2's default keys are: Buttons 1-4 (a, s, q, w), Start (2), Coin (6), Movement (g, d, r, f)
# ### Because Joysticks 3 and 4 are in portrait (not landscape) mode, the axes needed to be mapped differently (eg for Joystick 3, left and right became down and up).
# ### For Joystick 3 (Player 1), Buttons 1 to 4 are for fire and jump and so on.  Button 5 will start Player 1; Button 6 will start Player 2; Holding Button 5 and pressing Button 6 together will exit emulator in line with Retroarch hotkey
# ### For Joystick 4 (Player 2), Buttons 1 to 4 are for fire and jump and so on.  Button 5 will start Player 2; Button 6 does nothing; Holding Button 5 and pressing Button 6 together will exit emulator in line with Retroarch hotkey
# #joy3keys="--ui-axismap X1=KEY_DOWN:KEY_UP,Y1=KEY_RIGHT:KEY_LEFT \
	# --ui-buttonmap a=KEY_LEFTCTRL,b=KEY_LEFTALT,x=KEY_SPACE,y=KEY_LEFTSHIFT,back=KEY_5+KEY_1,start=KEY_6+KEY_2,back+start=KEY_SPACE+KEY_ESC"

# #joy4keys="--ui-axismap X1=KEY_F:KEY_R,Y1=KEY_G:KEY_D \
	# --ui-buttonmap a=KEY_A,b=KEY_S,x=KEY_Q,y=KEY_W,back=KEY_6+KEY_2,start=KEY_UNKNOWN,back+start=KEY_SPACE+KEY_ESC"

# ## joycommand="$basic $joy3restricted $joy3keys & $basic $joy4restricted $joy4keys &"
# ## joycommand="$basic $joy3unrestricted $joy3keys & $basic $joy4unrestricted $joy4keys &"

# ### Arcade Games in Arcade-Vertical folder - lr-mame2003 - in portrait mode that use 4 way restricted joysticks - 132 of 208 identified games
# #RestrictedArcadeGamesPortraitMode=""alibaba.zip"|"amidar.zip"|"armwrest.zip"|"astinvad.zip"|"atetris.zip"|"anteater.zip"|"armorcar.zip"|"astrob.zip"|"astrof.zip"|"bagman.zip"|"ballbomb.zip"|"barrier.zip"|"blkhole.zip"|"blasto.zip"|"blockade.zip"|"btime.zip"|"carjmbre.zip"|"carnival.zip"|"cavelon.zip"|"chameleo.zip"|"checkman.zip"|"chinhero.zip"|"circusc.zip"|"ckong.zip"|"commando.zip"|"congo.zip"|"dazzler.zip"|"devilfsh.zip"|"digdug.zip"|"digdug2.zip"|"digger.zip"|"disco.zip"|"dkong.zip"|"dkong3.zip"|"dkongjr.zip"|"docastle.zip"|"dommy.zip"|"dorodon.zip"|"frogger.zip"|"galaga.zip"|"galaxian.zip"|"galxwars.zip"|"guzzler.zip"|"invrvnge.zip"|"invinco.zip"|"jjack.zip"|"joust2.zip"|"jrpacman.zip"|"jumpcoas.zip"|"jungler.zip"|"kchamp.zip"|"kicker.zip"|"kingball.zip"|"ladybug.zip"|"lasso.zip"|"levers.zip"|"lnc.zip"|"locomotn.zip"|"logger.zip"|"lrescue.zip"|"lupin3.zip"|"mappy.zip"|"marvins.zip"|"mikie.zip"|"mmonkey.zip"|"monsterb.zip"|"moonal2.zip"|"moonqsr.zip"|"mrdo.zip"|"mrflea.zip"|"mrjong.zip"|"mrtnt.zip"|"mspacman.zip"|"mystston.zip"|"naughtyb.zip"|"netwars.zip"|"olibochu.zip"|"ozmawars.zip"|"pacnpal.zip"|"pacplus.zip"|"pengo.zip"|"perestro.zip"|"pickin.zip"|"pignewt.zip"|"pisces.zip"|"pleiads.zip"|"pooyan.zip"|"popflame.zip"|"puckman.zip"|"pulsar.zip"|"qbert.zip"|"qbertqub.zip"|"qix.zip"|"radarscp.zip"|"retofinv.zip"|"rocnrope.zip"|"route16.zip"|"samurai.zip"|"tsamurai.zip"|"scregg.zip"|"sindbadm.zip"|"solarfox.zip"|"sonofphx.zip"|"invadpt2.zip"|"panic.zip"|"shollow.zip"|"spclaser.zip"|"sqbert.zip"|"streakng.zip"|"sbagman.zip"|"superpac.zip"|"superqix.zip"|"ssi.zip"|"swat.zip"|"tactcian.zip"|"tankbatt.zip"|"taxidrvr.zip"|"elecyoyo.zip"|"theend.zip"|"timelimt.zip"|"tomahawk.zip"|"todruaga.zip"|"tranqgun.zip"|"triplep.zip"|"tutankhm.zip"|"vanvan.zip"|"volfied.zip"|"vsgongf.zip"|"wiping.zip"|"warpwarp.zip"|"zigzag.zip"|"zzyzzyxx.zip""

# ### Arcade Games in landscape mode that use 4 way restricted joysticks - 208 of 208 identified games
# #RestrictedArcadeGamesLandscapeMode=""alibaba.zip"|"amidar.zip"|"armwrest.zip"|"astinvad.zip"|"atetris.zip"|"anteater.zip"|"armorcar.zip"|"astrob.zip"|"astrof.zip"|"bagman.zip"|"ballbomb.zip"|"barrier.zip"|"blkhole.zip"|"blasto.zip"|"blockade.zip"|"btime.zip"|"carjmbre.zip"|"carnival.zip"|"cavelon.zip"|"chameleo.zip"|"checkman.zip"|"chinhero.zip"|"circusc.zip"|"ckong.zip"|"commando.zip"|"congo.zip"|"dazzler.zip"|"devilfsh.zip"|"digdug.zip"|"digdug2.zip"|"digger.zip"|"disco.zip"|"dkong.zip"|"dkong3.zip"|"dkongjr.zip"|"docastle.zip"|"dommy.zip"|"dorodon.zip"|"frogger.zip"|"galaga.zip"|"galaxian.zip"|"galxwars.zip"|"guzzler.zip"|"invrvnge.zip"|"invinco.zip"|"jjack.zip"|"joust2.zip"|"jrpacman.zip"|"jumpcoas.zip"|"jungler.zip"|"kchamp.zip"|"kicker.zip"|"kingball.zip"|"ladybug.zip"|"lasso.zip"|"levers.zip"|"lnc.zip"|"locomotn.zip"|"logger.zip"|"lrescue.zip"|"lupin3.zip"|"mappy.zip"|"marvins.zip"|"mikie.zip"|"mmonkey.zip"|"monsterb.zip"|"moonal2.zip"|"moonqsr.zip"|"mrdo.zip"|"mrflea.zip"|"mrjong.zip"|"mrtnt.zip"|"mspacman.zip"|"mystston.zip"|"naughtyb.zip"|"netwars.zip"|"olibochu.zip"|"ozmawars.zip"|"pacnpal.zip"|"pacplus.zip"|"pengo.zip"|"perestro.zip"|"pickin.zip"|"pignewt.zip"|"pisces.zip"|"pleiads.zip"|"pooyan.zip"|"popflame.zip"|"puckman.zip"|"pacman.zip"|"pulsar.zip"|"qbert.zip"|"qbertqub.zip"|"qix.zip"|"radarscp.zip"|"retofinv.zip"|"rocnrope.zip"|"route16.zip"|"samurai.zip"|"tsamurai.zip"|"scregg.zip"|"sindbadm.zip"|"solarfox.zip"|"sonofphx.zip"|"invadpt2.zip"|"panic.zip"|"shollow.zip"|"spclaser.zip"|"sqbert.zip"|"streakng.zip"|"sbagman.zip"|"superpac.zip"|"superqix.zip"|"ssi.zip"|"swat.zip"|"tactcian.zip"|"tankbatt.zip"|"taxidrvr.zip"|"elecyoyo.zip"|"theend.zip"|"timelimt.zip"|"tomahawk.zip"|"todruaga.zip"|"tranqgun.zip"|"triplep.zip"|"tutankhm.zip"|"vanvan.zip"|"volfied.zip"|"vsgongf.zip"|"wiping.zip"|"warpwarp.zip"|"zigzag.zip"|"zzyzzyxx.zip"|"alphaho.zip"|"pacnchmp.zip"|"comotion.zip"|"copsnrob.zip"|"cosmicg.zip"|"cosmos.zip"|"crash.zip"|"crush.zip"|"redufo.zip"|"diamond.zip"|"dorunrun.zip"|"dominos.zip"|"drmicro.zip"|"drgnbstr.zip"|"dremshpr.zip"|"elvactr.zip"|"eyes.zip"|"firetrap.zip"|"40love.zip"|"galpanic.zip"|"gundealr.zip"|"hardhat.zip"|"headon.zip"|"headon2.zip"|"heiankyo.zip"|"hexa.zip"|"hustle.zip"|"intrepid.zip"|"ironhors.zip"|"karianx.zip"|"kungfum.zip"|"lvgirl94.zip"|"logicpro.zip"|"logicpr2.zip"|"msjiken.zip"|"kikcubic.zip"|"mineswpr.zip"|"mtrap.zip"|"dowild.zip"|"mrgoemon.zip"|"natodef.zip"|"rallyx.zip"|"nrallyx.zip"|"pepper2.zip"|"pettanp.zip"|"popeye.zip"|"punchout.zip"|"raiders5.zip"|"rampage.zip"|"reikaids.zip"|"robby.zip"|"rthunder.zip"|"sidetrac.zip"|"schaser.zip"|"spaceinv.zip"|"spacezap.zip"|"spectar.zip"|"springer.zip"|"stratvox.zip"|"sia2650.zip"|"spnchout.zip"|"tapper.zip"|"rbtapper.zip"|"targ.zip"|"telmahjn.zip"|"theglob.zip"|"thief.zip"|"timber.zip"|"toypop.zip"|"wwjgtin.zip"|"wndrmomo.zip"|"yamyam.zip"|"zerozone.zip"|"zookeep.zip"|"pairs.zip"|"higemaru.zip"|"elecyoy2.zip"|"arkangc.zip"|"arkanoid.zip"|"arkatayt.zip"|"arkatour.zip"|"arkbl2.zip"|"arkbl3.zip"|"arkbloc2.zip"|"arkblock.zip"|"arknid2j.zip"|"arknid2u.zip"|"arknoid2.zip"|"arknoidj.zip"|"arknoidu.zip"|"arknoiuo.zip"|"arkretrn.zip"|"tempest.zip"|"tempest1.zip"|"tempest2.zip"|"tempest3.zip"|"temptube.zip""

# ####### END SECTION --------------------


### Execute the driver with the configuration you need
# $1 is the name of the emulation, not the name of the software used
# it is intellivision not jzintv

if [ "$debug" -ge "1" ]; then echo "rcos: $1" >> $logfile; fi


joycommand=""
sleepfix="sleep 1"
sleepfixhack="sleep 1 &&"

# these are for the debug log
if [ "$debug" -ge "1" ]; then
	echo "rcos: xpad = $xpad" >> $logfile
	echo "rcos: xboxdrv = $xboxdrv" >> $logfile
fi

# Override arcade list use
if [ "$arcaderomlists" = "0" ]; then  
	arcaderom4way=""
	arcaderomdial=""
	arcaderomtrackball=""
	arcaderomanalog=""
fi

case $1 in
	mame-mame4all)
	tempFourWay=$(echo $My4wayList | grep $rom)
	tempFourWayFBA=$(echo RestrictedArcadeGamesFBA | grep $rom)
	tempTrackball=$(echo $TrackballGames | grep $rom)
	tempAnalog=$(echo $AnalogGames | grep $rom)
	tempDial=$(echo $DialGames | grep $rom)
	if [ "$tempFourWay" ] && [ "$arcaderomlists" = "1" ]; then 
		xtemp="$p1_profile $arcaderom4way"
		p1_profile=$xtemp
		xtemp="$p2_profile $arcaderom4way"
		p2_profile=$xtemp
		xtemp="$p3_profile $arcaderom4way"
		p3_profile=$xtemp
		xtemp="$p4_profile $arcaderom4way"
		p4_profile=$xtemp
		if [ "$debug" -ge "1" ]; then echo "rcos: 4-way game" >> $logfile; fi
	elif [ "$tempFourWayFBA" ] && [ "$arcaderomlists" = "1" ]; then 
		xtemp="$p1_profile $arcaderom4way"
		p1_profile=$xtemp
		xtemp="$p2_profile $arcaderom4way"
		p2_profile=$xtemp
		xtemp="$p3_profile $arcaderom4way"
		p3_profile=$xtemp
		xtemp="$p4_profile $arcaderom4way"
		p4_profile=$xtemp
		if [ "$debug" -ge "1" ]; then echo "rcos: 4-way game" >> $logfile; fi
	elif [ "$tempTrackball" ] && [ "$arcaderomlists" = "1" ]; then 
		xtemp="$p1_profile $arcaderomtrackball"
		p1_profile=$xtemp
		xtemp="$p2_profile $arcaderomtrackball"
		p2_profile=$xtemp
		xtemp="$p3_profile $arcaderomtrackball"
		p3_profile=$xtemp
		xtemp="$p4_profile $arcaderomtrackball"
		p4_profile=$xtemp
		if [ "$debug" -ge "1" ]; then echo "rcos: trackball game" >> $logfile; fi
	elif [ "$tempDial" ] && [ "$arcaderomlists" = "1" ]; then 
		xtemp="$p1_profile $arcaderomdial"
		p1_profile=$xtemp
		xtemp="$p2_profile $arcaderomdial"
		p2_profile=$xtemp
		xtemp="$p3_profile $arcaderomdial"
		p3_profile=$xtemp
		xtemp="$p4_profile $arcaderomdial"
		p4_profile=$xtemp
		if [ "$debug" -ge "1" ]; then echo "rcos: dial game" >> $logfile; fi
	elif [ "$tempAnalog" ] && [ "$arcaderomlists" = "1" ]; then 
		xtemp="$p1_profile $arcaderomanalog"
		p1_profile=$xtemp
		xtemp="$p2_profile $arcaderomanalog"
		p2_profile=$xtemp
		xtemp="$p3_profile $arcaderomanalog"
		p3_profile=$xtemp
		xtemp="$p4_profile $arcaderomanalog"
		p4_profile=$xtemp
		if [ "$debug" -ge "1" ]; then echo "rcos: analog game" >> $logfile; fi
	else
		echo " nothing "  > /dev/null 2>&1
		if [ "$debug" -ge "1" ]; then echo "rcos: not a dial, analog, trackball or 4-way game" >> $logfile; fi
	fi
	;;

	lr-mam*)
	tempFourWay=$(echo $My4wayList | grep $rom)
	tempFourWayFBA=$(echo RestrictedArcadeGamesFBA | grep $rom)
	tempTrackball=$(echo $TrackballGames | grep $rom)
	tempAnalog=$(echo $AnalogGames | grep $rom)
	tempDial=$(echo $DialGames | grep $rom)
	if [ "$tempFourWay" ] && [ "$arcaderomlists" = "1" ]; then 
		xtemp="$p1_profile $arcaderom4way"
		p1_profile=$xtemp
		xtemp="$p2_profile $arcaderom4way"
		p2_profile=$xtemp
		xtemp="$p3_profile $arcaderom4way"
		p3_profile=$xtemp
		xtemp="$p4_profile $arcaderom4way"
		p4_profile=$xtemp
		if [ "$debug" -ge "1" ]; then echo "rcos: 4-way game" >> $logfile; fi
	elif [ "$tempFourWayFBA" ] && [ "$arcaderomlists" = "1" ]; then 
		xtemp="$p1_profile $arcaderom4way"
		p1_profile=$xtemp
		xtemp="$p2_profile $arcaderom4way"
		p2_profile=$xtemp
		xtemp="$p3_profile $arcaderom4way"
		p3_profile=$xtemp
		xtemp="$p4_profile $arcaderom4way"
		p4_profile=$xtemp
		if [ "$debug" -ge "1" ]; then echo "rcos: 4-way game" >> $logfile; fi
	elif [ "$tempTrackball" ] && [ "$arcaderomlists" = "1" ]; then 
		xtemp="$p1_profile $arcaderomtrackball"
		p1_profile=$xtemp
		xtemp="$p2_profile $arcaderomtrackball"
		p2_profile=$xtemp
		xtemp="$p3_profile $arcaderomtrackball"
		p3_profile=$xtemp
		xtemp="$p4_profile $arcaderomtrackball"
		p4_profile=$xtemp
		if [ "$debug" -ge "1" ]; then echo "rcos: trackball game" >> $logfile; fi
	elif [ "$tempDial" ] && [ "$arcaderomlists" = "1" ]; then 
		xtemp="$p1_profile $arcaderomdial"
		p1_profile=$xtemp
		xtemp="$p2_profile $arcaderomdial"
		p2_profile=$xtemp
		xtemp="$p3_profile $arcaderomdial"
		p3_profile=$xtemp
		xtemp="$p4_profile $arcaderomdial"
		p4_profile=$xtemp
		if [ "$debug" -ge "1" ]; then echo "rcos: dial game" >> $logfile; fi
	elif [ "$tempAnalog" ] && [ "$arcaderomlists" = "1" ]; then 
		xtemp="$p1_profile $arcaderomanalog"
		p1_profile=$xtemp
		xtemp="$p2_profile $arcaderomanalog"
		p2_profile=$xtemp
		xtemp="$p3_profile $arcaderomanalog"
		p3_profile=$xtemp
		xtemp="$p4_profile $arcaderomanalog"
		p4_profile=$xtemp
		if [ "$debug" -ge "1" ]; then echo "rcos: analog game" >> $logfile; fi
	else
		echo " nothing "  > /dev/null 2>&1
		if [ "$debug" -ge "1" ]; then echo "rcos: not a dial, analog, trackball or 4-way game" >> $logfile; fi
	fi
	;;

	mame*)
	tempFourWay=$(echo $My4wayList | grep $rom)
	tempFourWayFBA=$(echo RestrictedArcadeGamesFBA | grep $rom)
	tempTrackball=$(echo $TrackballGames | grep $rom)
	tempAnalog=$(echo $AnalogGames | grep $rom)
	tempDial=$(echo $DialGames | grep $rom)
	if [ "$tempFourWay" ] && [ "$arcaderomlists" = "1" ]; then 
		xtemp="$p1_profile $arcaderom4way"
		p1_profile=$xtemp
		xtemp="$p2_profile $arcaderom4way"
		p2_profile=$xtemp
		xtemp="$p3_profile $arcaderom4way"
		p3_profile=$xtemp
		xtemp="$p4_profile $arcaderom4way"
		p4_profile=$xtemp
		if [ "$debug" -ge "1" ]; then echo "rcos: 4-way game" >> $logfile; fi
	elif [ "$tempFourWayFBA" ] && [ "$arcaderomlists" = "1" ]; then 
		xtemp="$p1_profile $arcaderom4way"
		p1_profile=$xtemp
		xtemp="$p2_profile $arcaderom4way"
		p2_profile=$xtemp
		xtemp="$p3_profile $arcaderom4way"
		p3_profile=$xtemp
		xtemp="$p4_profile $arcaderom4way"
		p4_profile=$xtemp
		if [ "$debug" -ge "1" ]; then echo "rcos: 4-way game" >> $logfile; fi
	elif [ "$tempTrackball" ] && [ "$arcaderomlists" = "1" ]; then 
		xtemp="$p1_profile $arcaderomtrackball"
		p1_profile=$xtemp
		xtemp="$p2_profile $arcaderomtrackball"
		p2_profile=$xtemp
		xtemp="$p3_profile $arcaderomtrackball"
		p3_profile=$xtemp
		xtemp="$p4_profile $arcaderomtrackball"
		p4_profile=$xtemp
		if [ "$debug" -ge "1" ]; then echo "rcos: trackball game" >> $logfile; fi
	elif [ "$tempDial" ] && [ "$arcaderomlists" = "1" ]; then 
		xtemp="$p1_profile $arcaderomdial"
		p1_profile=$xtemp
		xtemp="$p2_profile $arcaderomdial"
		p2_profile=$xtemp
		xtemp="$p3_profile $arcaderomdial"
		p3_profile=$xtemp
		xtemp="$p4_profile $arcaderomdial"
		p4_profile=$xtemp
		if [ "$debug" -ge "1" ]; then echo "rcos: dial game" >> $logfile; fi
	elif [ "$tempAnalog" ] && [ "$arcaderomlists" = "1" ]; then 
		xtemp="$p1_profile $arcaderomanalog"
		p1_profile=$xtemp
		xtemp="$p2_profile $arcaderomanalog"
		p2_profile=$xtemp
		xtemp="$p3_profile $arcaderomanalog"
		p3_profile=$xtemp
		xtemp="$p4_profile $arcaderomanalog"
		p4_profile=$xtemp
		if [ "$debug" -ge "1" ]; then echo "rcos: analog game" >> $logfile; fi
	else
		echo " nothing "  > /dev/null 2>&1
		if [ "$debug" -ge "1" ]; then echo "rcos: not a dial, analog, trackball or 4-way game" >> $logfile; fi
	fi
	;;
	
	arcade)
	tempFourWay=$(echo $My4wayList | grep $rom)
	tempFourWayFBA=$(echo RestrictedArcadeGamesFBA | grep $rom)
	tempTrackball=$(echo $TrackballGames | grep $rom)
	tempAnalog=$(echo $AnalogGames | grep $rom)
	tempDial=$(echo $DialGames | grep $rom)
	if [ "$tempFourWay" ] && [ "$arcaderomlists" = "1" ]; then 
		xtemp="$p1_profile $arcaderom4way"
		p1_profile=$xtemp
		xtemp="$p2_profile $arcaderom4way"
		p2_profile=$xtemp
		xtemp="$p3_profile $arcaderom4way"
		p3_profile=$xtemp
		xtemp="$p4_profile $arcaderom4way"
		p4_profile=$xtemp
		if [ "$debug" -ge "1" ]; then echo "rcos: 4-way game" >> $logfile; fi
	elif [ "$tempFourWayFBA" ] && [ "$arcaderomlists" = "1" ]; then 
		xtemp="$p1_profile $arcaderom4way"
		p1_profile=$xtemp
		xtemp="$p2_profile $arcaderom4way"
		p2_profile=$xtemp
		xtemp="$p3_profile $arcaderom4way"
		p3_profile=$xtemp
		xtemp="$p4_profile $arcaderom4way"
		p4_profile=$xtemp
		if [ "$debug" -ge "1" ]; then echo "rcos: 4-way game" >> $logfile; fi
	elif [ "$tempTrackball" ] && [ "$arcaderomlists" = "1" ]; then 
		xtemp="$p1_profile $arcaderomtrackball"
		p1_profile=$xtemp
		xtemp="$p2_profile $arcaderomtrackball"
		p2_profile=$xtemp
		xtemp="$p3_profile $arcaderomtrackball"
		p3_profile=$xtemp
		xtemp="$p4_profile $arcaderomtrackball"
		p4_profile=$xtemp
		if [ "$debug" -ge "1" ]; then echo "rcos: trackball game" >> $logfile; fi
	elif [ "$tempDial" ] && [ "$arcaderomlists" = "1" ]; then 
		xtemp="$p1_profile $arcaderomdial"
		p1_profile=$xtemp
		xtemp="$p2_profile $arcaderomdial"
		p2_profile=$xtemp
		xtemp="$p3_profile $arcaderomdial"
		p3_profile=$xtemp
		xtemp="$p4_profile $arcaderomdial"
		p4_profile=$xtemp
		if [ "$debug" -ge "1" ]; then echo "rcos: dial game" >> $logfile; fi
	elif [ "$tempAnalog" ] && [ "$arcaderomlists" = "1" ]; then 
		xtemp="$p1_profile $arcaderomanalog"
		p1_profile=$xtemp
		xtemp="$p2_profile $arcaderomanalog"
		p2_profile=$xtemp
		xtemp="$p3_profile $arcaderomanalog"
		p3_profile=$xtemp
		xtemp="$p4_profile $arcaderomanalog"
		p4_profile=$xtemp
		if [ "$debug" -ge "1" ]; then echo "rcos: analog game" >> $logfile; fi
	else
		echo " nothing "  > /dev/null 2>&1
		if [ "$debug" -ge "1" ]; then echo "rcos: not a dial, analog, trackball or 4-way game" >> $logfile; fi
	fi
	;;

	fba)
	tempFourWay=$(echo $My4wayList | grep $rom)
	tempFourWayFBA=$(echo RestrictedArcadeGamesFBA | grep $rom)
	tempTrackball=$(echo $TrackballGames | grep $rom)
	tempAnalog=$(echo $AnalogGames | grep $rom)
	tempDial=$(echo $DialGames | grep $rom)
	if [ "$tempFourWay" ] && [ "$arcaderomlists" = "1" ]; then 
		xtemp="$p1_profile $arcaderom4way"
		p1_profile=$xtemp
		xtemp="$p2_profile $arcaderom4way"
		p2_profile=$xtemp
		xtemp="$p3_profile $arcaderom4way"
		p3_profile=$xtemp
		xtemp="$p4_profile $arcaderom4way"
		p4_profile=$xtemp
		if [ "$debug" -ge "1" ]; then echo "rcos: 4-way game" >> $logfile; fi
	elif [ "$tempFourWayFBA" ] && [ "$arcaderomlists" = "1" ]; then 
		xtemp="$p1_profile $arcaderom4way"
		p1_profile=$xtemp
		xtemp="$p2_profile $arcaderom4way"
		p2_profile=$xtemp
		xtemp="$p3_profile $arcaderom4way"
		p3_profile=$xtemp
		xtemp="$p4_profile $arcaderom4way"
		p4_profile=$xtemp
		if [ "$debug" -ge "1" ]; then echo "rcos: 4-way game" >> $logfile; fi
	elif [ "$tempTrackball" ] && [ "$arcaderomlists" = "1" ]; then 
		xtemp="$p1_profile $arcaderomtrackball"
		p1_profile=$xtemp
		xtemp="$p2_profile $arcaderomtrackball"
		p2_profile=$xtemp
		xtemp="$p3_profile $arcaderomtrackball"
		p3_profile=$xtemp
		xtemp="$p4_profile $arcaderomtrackball"
		p4_profile=$xtemp
		if [ "$debug" -ge "1" ]; then echo "rcos: trackball game" >> $logfile; fi
	elif [ "$tempDial" ] && [ "$arcaderomlists" = "1" ]; then 
		xtemp="$p1_profile $arcaderomdial"
		p1_profile=$xtemp
		xtemp="$p2_profile $arcaderomdial"
		p2_profile=$xtemp
		xtemp="$p3_profile $arcaderomdial"
		p3_profile=$xtemp
		xtemp="$p4_profile $arcaderomdial"
		p4_profile=$xtemp
		if [ "$debug" -ge "1" ]; then echo "rcos: dial game" >> $logfile; fi
	elif [ "$tempAnalog" ] && [ "$arcaderomlists" = "1" ]; then 
		xtemp="$p1_profile $arcaderomanalog"
		p1_profile=$xtemp
		xtemp="$p2_profile $arcaderomanalog"
		p2_profile=$xtemp
		xtemp="$p3_profile $arcaderomanalog"
		p3_profile=$xtemp
		xtemp="$p4_profile $arcaderomanalog"
		p4_profile=$xtemp
		if [ "$debug" -ge "1" ]; then echo "rcos: analog game" >> $logfile; fi
	else
		echo " nothing "  > /dev/null 2>&1
		if [ "$debug" -ge "1" ]; then echo "rcos: not a dial, analog, trackball or 4-way game" >> $logfile; fi
	fi
	;;

	Xdaphne)
	### Example of where to put your custom commands
	## xtemp="$p1_profile $new_command"
		xtemp="$p1_profile"
		p1_profile=$xtemp
		xtemp="$p2_profile"
		p2_profile=$xtemp
		if [ "$debug" -ge "1" ]; then echo "rcos: $1 profile" >> $logfile; fi
	;;

	Xscummvm)
		# xtemp=`echo $p1_lconfig | sed "s/--deadzone/$scummVM --deadzone/g" | sed "s|sleep..|sleep 1 \&\&|g"`
		# p1_lconfig="$xtemp"
		# p1_profile=""
		xtemp="$p1_profile $scummVM"
		p1_profile=$xtemp
		xtemp="$p2_profile"
		p2_profile=$xtemp
		if [ "$debug" -ge "1" ]; then echo "rcos: $1 profile" >> $logfile; fi
	;;

	Xamiga)
		xtemp="$p1_profile $amigaplayer1"
		p1_profile=$xtemp
		xtemp="$p2_profile $amigaplayer2"
		p2_profile=$xtemp
		if [ "$debug" -ge "1" ]; then echo "rcos: $1 profile" >> $logfile; fi
	;;

	Xuae4arm)
		xtemp="$p1_profile $amigaplayer1"
		p1_profile=$xtemp
		xtemp="$p2_profile $amigaplayer2"
		p2_profile=$xtemp
		if [ "$debug" -ge "1" ]; then echo "rcos: $1 profile" >> $logfile; fi
	;;

	Xintellivision)
	### Example of where to put your custom commands
	## xtemp="$p1_profile $new_command"
		xtemp="$p1_profile"
		p1_profile=$xtemp
		xtemp="$p2_profile"
		p2_profile=$xtemp
		xtemp="$p3_profile"
		p3_profile=$xtemp
		xtemp="$p4_profile"
		p4_profile=$xtemp
		if [ "$debug" -ge "1" ]; then echo "rcos: $1 profile" >> $logfile; fi
	;;

	Xodyssey)
	### Example of where to put your custom commands
	## xtemp="$p1_profile $new_command"
		xtemp="$p1_profile"
		p1_profile=$xtemp
		xtemp="$p2_profile"
		p2_profile=$xtemp
		xtemp="$p3_profile"
		p3_profile=$xtemp
		xtemp="$p4_profile"
		p4_profile=$xtemp
		if [ "$debug" -ge "1" ]; then echo "rcos: $1 profile" >> $logfile; fi
	;;

	Cvideopac)
	### Example of where to put your custom commands
	## xtemp="$p1_profile $new_command"
		xtemp="$p1_profile"
		p1_profile=$xtemp
		xtemp="$p2_profile"
		p2_profile=$xtemp
		xtemp="$p3_profile"
		p3_profile=$xtemp
		xtemp="$p4_profile"
		p4_profile=$xtemp
		if [ "$debug" -ge "1" ]; then echo "rcos: $1 profile" >> $logfile; fi
	;;

	Cmsx)
	### Example of where to put your custom commands
	## xtemp="$p1_profile $new_command"
		xtemp="$p1_profile"
		p1_profile=$xtemp
		xtemp="$p2_profile"
		p2_profile=$xtemp
		xtemp="$p3_profile"
		p3_profile=$xtemp
		xtemp="$p4_profile"
		p4_profile=$xtemp
		if [ "$debug" -ge "1" ]; then echo "rcos: $1 profile" >> $logfile; fi
	;;

	pc)
		xtemp="$p1_profile $lim_axis"
		p1_profile=$xtemp
		xtemp="$p2_profile $lim_axis"
		p2_profile=$xtemp
		xtemp="$p3_profile $lim_axis"
		p3_profile=$xtemp
		xtemp="$p4_profile $lim_axis"
		p4_profile=$xtemp
		if [ "$debug" -ge "1" ]; then echo "rcos: $1 profile" >> $logfile; fi
	;;

	duke3d)
	#sudo rm /dev/input/js0
	;;

	Cquake)
	### Example of where to put your custom commands
	## xtemp="$p1_profile $new_command"
		xtemp="$p1_profile"
		p1_profile=$xtemp
		xtemp="$p2_profile"
		p2_profile=$xtemp
		xtemp="$p3_profile"
		p3_profile=$xtemp
		xtemp="$p4_profile"
		p4_profile=$xtemp
		if [ "$debug" -ge "1" ]; then echo "rcos: $1 profile" >> $logfile; fi
	;;

	*)	# Default case, just load basic config
		if [ "$debug" -ge "1" ]; then echo "rcos: $1 default profile used" >> $logfile; fi
	;;
esac

# if we have both vend:prod and by-id, default to vend:prod (arbitrary)
if [ "$p1_id" ]; then
	xtemp="$p1_profile --device-by-id $p1_id"
	p1_profile=$xtemp
elif [ "$p1_bid" ]; then
	xtemp="$p1_profile --evdev $p1_bid"
	p1_profile=$xtemp
fi
if [ "$p2_id" ]; then
	xtemp="$p2_profile --device-by-id $p2_id"
	p2_profile=$xtemp
elif [ "$p2_bid" ]; then
	xtemp="$p2_profile --evdev $p2_bid"
	p2_profile=$xtemp
fi
if [ "$p3_id" ]; then
	xtemp="$p3_profile --device-by-id $p3_id"
	p3_profile=$xtemp
elif [ "$p3_bid" ]; then
	xtemp="$p3_profile --evdev $p3_bid"
	p3_profile=$xtemp
fi
if [ "$p4_id" ]; then
	xtemp="$p4_profile --device-by-id $p4_id"
	p4_profile=$xtemp
elif [ "$p4_bid" ]; then
	xtemp="$p4_profile --evdev $p4_bid"
	p4_profile=$xtemp
fi

# ## Joystick select by ID
# if [ "$p1_id" ]; then
	# xtemp="$p1_profile --device-by-id $p1_id"
	# p1_profile=$xtemp
# fi
# if [ "$p2_id" ]; then
	# xtemp="$p2_profile --device-by-id $p2_id"
	# p2_profile=$xtemp
# fi
# if [ "$p3_id" ]; then
	# xtemp="$p3_profile --device-by-id $p3_id"
	# p3_profile=$xtemp
# fi
# if [ "$p4_id" ]; then
	# xtemp="$p4_profile --device-by-id $p4_id"
	# p4_profile=$xtemp
# fi
# if [ "$p1_bid" ]; then
	# xtemp="$p1_profile --evdev $p1_bid"
	# p1_profile=$xtemp
# fi
# if [ "$p2_bid" ]; then
	# xtemp="$p2_profile --evdev $p2_bid"
	# p2_profile=$xtemp
# fi
# if [ "$p3_bid" ]; then
	# xtemp="$p3_profile --evdev $p3_bid"
	# p3_profile=$xtemp
# fi
# if [ "$p4_bid" ]; then
	# xtemp="$p4_profile --evdev $p4_bid"
	# p4_profile=$xtemp
# fi

if [ "$xbdctrlr" -le "$controllers" ]; then
	controllers=$xbdctrlr
fi

case $controllers in
	4)
	joycommand="$launchPrefix $p1_profile $p1_lconfig $launchSuffix & sleep 1 && $launchPrefix $p2_profile $p2_lconfig $launchSuffix & sleep 1 && $launchPrefix $p3_profile $p3_lconfig $launchSuffix & sleep 1 && $launchPrefix $p4_profile $p4_lconfig $launchSuffix &"
	;;
	3)
	joycommand="$launchPrefix $p1_profile $p1_lconfig $launchSuffix & sleep 1 && $launchPrefix $p2_profile $p2_lconfig $launchSuffix & sleep 1 && $launchPrefix $p3_profile $p3_lconfig $launchSuffix &"
	;;
	2)
	joycommand="$launchPrefix $p1_profile $p1_lconfig $launchSuffix & sleep 1 && $launchPrefix $p2_profile $p2_lconfig $launchSuffix &"
	;;
	1)
	joycommand="$launchPrefix $p1_profile $p1_lconfig $launchSuffix &"
	;;
esac

sudo rm -f /dev/input/js*			## TESTING THIS
if [ "$debug" -ge "1" ]; then ls /dev/input/j* >> $logfile; fi

joycommand=$( echo "$joycommand" | xargs )		## This is to trim whitespace

# we should run the command, user wants xboxdrv to run
if [ "$xboxdrv" = 1 ] || [ "$xboxdrv" = 2 ]; then
	eval "$joycommand" >/dev/null
	if [ "$debug" -ge "1" ]; then echo "rcos: $joycommand" >> $logfile; fi
fi

# Load calibration file??
if [ "$loadcalibrationfile" = 1 ]; then
	if [ -f "$calfilelocation" ]; then
	$calfilelocation" > /dev/null 2>&1"
	if [ "$debug" -ge "1" ]; then echo "rcos: $calfilelocation loaded" >> $logfile; fi
	fi
fi

if [ "$debug" -ge "2" ]; then 
echo "rcos: end: lsmod" >> $logfile
lsmod >> $logfile
fi

exit 0