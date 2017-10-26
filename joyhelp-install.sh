#!/bin/sh
# Joyhelp install script
#

cd joyhelp

# Make Backups
sudo cp /etc/rc.local /etc/rc.local.bak
# You may not have these files:
cp /opt/retropie/configs/all/runcommand-onstart.sh /opt/retropie/configs/all/runcommand-onstart.sh.bak 
cp /opt/retropie/configs/all/runcommand-onend.sh /opt/retropie/configs/all/runcommand-onend.sh.bak

# Fix Permissions
chmod +x *.sh
chown pi:pi *

# Create install directories
mkdir /opt/retropie/configs/all/joyhelp
mkdir /opt/retropie/configs/all/joyhelp/controller_configs

# Copy the files
cp joyhelp.sh ~/RetroPie/retropiemenu/
cp configfix.sh /opt/retropie/configs/all/joyhelp/
cp rcfix.dat /opt/retropie/configs/all/joyhelp/
cp rcfix.sh /opt/retropie/configs/all/joyhelp/
cp runcommand-onstart.sh /opt/retropie/configs/all/
cp runcommand-onend.sh /opt/retropie/configs/all/
cp controller_configs/*.cfg /opt/retropie/configs/all/joyhelp/controller_configs/
