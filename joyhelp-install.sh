#!/bin/sh
# Joyhelp install script
#

cd joyhelp

# Make Backups
sudo cp /etc/rc.local /etc/rc.local.bakup
# You may not have these files:
cp /opt/retropie/configs/all/runcommand-onstart.sh /opt/retropie/configs/all/runcommand-onstart.sh.bakup
cp /opt/retropie/configs/all/runcommand-onend.sh /opt/retropie/configs/all/runcommand-onend.sh.bakup

# Fix Permissions
chmod +x *.sh
chmod +x .scripts/*.sh
chown pi:pi *
chown pi:pi .scripts/*
chown pi:pi .configs/*

# Create install directories
mkdir /opt/retropie/configs/all/joyhelp
mkdir /opt/retropie/configs/all/joyhelp/controller_configs
mkdir /opt/retropie/configs/all/joyhelp/docs
mkdir /opt/retropie/configs/all/joyhelp/.configs
mkdir /opt/retropie/configs/all/joyhelp/.scripts

# Copy the files
cp joyhelp.sh ~/RetroPie/retropiemenu/
cp configfix.sh /opt/retropie/configs/all/joyhelp/
cp rcfix.sh /opt/retropie/configs/all/joyhelp/
cp rchelp.sh /opt/retropie/configs/all/joyhelp/
cp .scripts/rcfix.dat /opt/retropie/configs/all/joyhelp/
cp .scripts/runcommand-onstart.sh /opt/retropie/configs/all/
cp .scripts/runcommand-onend.sh /opt/retropie/configs/all/
cp controller_configs/*.cfg /opt/retropie/configs/all/joyhelp/controller_configs/
cp docs/* /opt/retropie/configs/all/joyhelp/docs/
