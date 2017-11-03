# Joyhelp (for RetroPie)
# Early beta version 0.3

A tool for managing xboxdrv/xpad startup and configs with RetroPie running on the Raspberry Pi. It makes it easy to swtich between running xboxdrv as a daemon, always-on, disable it, or start it only when a game is launched. You will probably want to install xboxdrv (Retropie Setup > Manage Packages > Manage Driver Packages > xboxdrv) before using this.

Your config (or a default) will be used for every mode.

Joyhelp appears under the RetroPie system as a new menu named "JOYHELP" so it is easy to use.

# Install Instructions
Currently the scripts assume the user/group will be pi:pi

### Clone and install
	# press F4 to go to the shell of your Raspberry Pi.
	git clone https://github.com/SoMuchCode/RetroPie-Scripts.git
	cd RetroPie-Scripts
	chmod +x joyhelp-install.sh
	./joyhelp-install.sh
	# Reboot your Pi and Joyhelp should appear in the menu.

### Reboot RetroPie

After rebooting...
Under the RetroPie main menu, there should be a new entry named "JOYHELP", choose option 10, Initialize joyhelp. This will parse your init file and look for an xboxdrv config file in it. If it finds one, it will use it, if not one will be created.

Once initialized, joyhelp uses the newly created '/opt/retropie/configs/all/joyhelp/joyhelp-config.cfg' so if you are great at creating custom configs you will put it here (if not, everything should still work fine.)

Every reboot, joyhelp looks at this config file and if it has changed, joyhelp will create new 'joyhelp-daemon.cfg' and 'joyhelp-nodaemon.cfg' which are used when launching in different modes.

# Joyhelp has several modes of operation:
There are settings for when you are in the RetroPie GUI, and different settings for when you are in-game. This way if you wish to use xpad most of the time and only enable xboxdrv when you need it to remap keys, Joyhelp can do that.

On game launch (if not running as a daemon), Joyhelp will use the 'runcommand-onstart.sh' script to see if there is a custom config for the system. If it finds one it will load it and use it.
	
If debug is set in the menu, joyhelp will log to:
/opt/retropie/configs/all/joyhelp/xdrv.log

# Manual Install Instructions
I have not thoroughly tested the installer yet... so here are the quick install instructions.

### Download and extract joyhelp
	git clone https://github.com/SoMuchCode/RetroPie-Scripts.git
	cd RetroPie-Scripts
	chmod +x joyhelp-install.sh

### Make backups first!!!
	sudo cp /etc/rc.local /etc/rc.local.bakup

	You may not have these files:
	cp /opt/retropie/configs/all/runcommand-onstart.sh /opt/retropie/configs/all/runcommand-onstart.sh.bakup
	cp /opt/retropie/configs/all/runcommand-onend.sh /opt/retropie/configs/all/runcommand-onend.sh.bakup

### Fix file permissions if needed
	chmod +x *.sh
	chmod +x .scripts/*.sh
	chown pi:pi *
	chown pi:pi .scripts/*
	chown pi:pi .configs/*
	
### Create install directories
	mkdir /opt/retropie/configs/all/joyhelp
	mkdir /opt/retropie/configs/all/joyhelp/controller_configs
	mkdir /opt/retropie/configs/all/joyhelp/docs
	mkdir /opt/retropie/configs/all/joyhelp/.configs
	mkdir /opt/retropie/configs/all/joyhelp/.scripts

### Copy the files
	cp joyhelp.sh ~/RetroPie/retropiemenu/
	cp configfix.sh /opt/retropie/configs/all/joyhelp/
	cp rcfix.sh /opt/retropie/configs/all/joyhelp/
	cp rchelp.sh /opt/retropie/configs/all/joyhelp/
	cp .scripts/rcfix.dat /opt/retropie/configs/all/joyhelp/
	cp .scripts/runcommand-onstart.sh /opt/retropie/configs/all/
	cp .scripts/runcommand-onend.sh /opt/retropie/configs/all/
	cp controller_configs/*.cfg /opt/retropie/configs/all/joyhelp/controller_configs/
	cp docs/* /opt/retropie/configs/all/joyhelp/docs/

### Reboot RetroPie

After rebooting...
Under the RetroPie main menu, there should be a new entry named "JOYHELP", choose option 10, Initialize joyhelp. This will parse your init file and look for an xboxdrv config file in it. If it finds one, it will use it, if not one will be created.
	
# Important
NOTE: These scripts will make changes to /etc/rc.local
your original will be copied to: /etc/rc.local.bakup

NOTE: These scripts will replace any runcommand-onstart.sh / runcommand-onend.sh scripts you may have setup. You will want to make backups of these files (if they exist on your system) before installing.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.