# Joyhelp (for RetroPie)
# Early beta version 0.2

A tool for managing xboxdrv/xpad startup and configs with RetroPie running on the Raspberry Pi. It makes it easy to swtich between running xboxdrv as a daemon, always-on, disable it, or start it only when a game is launched.

Your config (or a default) will be used for every mode.

Joyhelp appears under the RetroPie system as a new menu named "JOYHELP" so it is easy to use.

# Install Instructions
Currently the scripts assume the user/group will be pi:pi

I have not made an installer yet... so here are the quick install instructions.

### Download and extract joyhelp
	git clone https://github.com/SoMuchCode/RetroPie-Scripts.git
	cd RetroPie-Extra/joyhelp

### Make backups first!!!
	cp /opt/retropie/configs/all/runcommand-onend.sh /opt/retropie/configs/all/runcommand-onend.sh.bak
	cp /opt/retropie/configs/all/runcommand-onstart.sh /opt/retropie/configs/all/runcommand-onstart.sh.bak
	sudo cp /etc/rc.local /etc/rc.local.bak

	You may not have these files:
	cp /opt/retropie/configs/all/runcommand-onstart.sh /opt/retropie/configs/all/runcommand-onstart.sh.bak 
	cp /opt/retropie/configs/all/runcommand-onend.sh /opt/retropie/configs/all/runcommand-onend.sh.bak

### Fix file permissions
	chmod +x *.sh
	chown pi:pi *

### Create install directories
	mkdir /opt/retropie/configs/all/joyhelp
	mkdir /opt/retropie/configs/all/joyhelp/controller_configs

### Copy the files
	cp joyhelp.sh ~/RetroPie/retropiemenu/
	cp configfix.sh /opt/retropie/configs/all/joyhelp/
	cp rcfix.dat /opt/retropie/configs/all/joyhelp/
	cp rcfix.sh /opt/retropie/configs/all/joyhelp/
	cp runcommand-onstart.sh /opt/retropie/configs/all/
	cp runcommand-onend.sh /opt/retropie/configs/all/
	cp controller_configs/*.cfg /opt/retropie/configs/all/joyhelp/controller_configs/

### Reboot RetroPie

Under the RetroPie main menu, there should be a new
entry named "JOYHELP", choose option 10, Initialize
joyhelp. This will parse your init file and look for
an xboxdrv config file in it. If it finds one, it
will use it, if not one will be created.

Once initialized, joyhelp uses the newly created
/opt/retropie/configs/all/joyhelp/joyhelp-config.cfg
so if you are great at creating custom configs you
will put it here.

Every reboot, joyhelp looks at this config file and
creates joyhelp-daemon.cfg and joyhelp-nodaemon.cfg
which are used when launching in different modes.

# Joyhelp has several modes of operation:
	0 = Disable: xboxdrv config won't be loaded at boot.
	1 = AUTO MODE: always use xboxdrv, can be daemon or not depending on config file: joyhelp-config.cfg
	2 = NO daemon mode
	3 = Forced daemon mode
	4 = Enabled only in game / rom / emulator (NOT daemon mode)

On game launch modes: 1 (if not running as a daemon), 2, and 4 will use the 'runcommand-onstart.sh' script to see if there is a custom config for the system. If it finds one it will load it. Look at the file to see how it works.
	
If debug is set in the menu, joyhelp will log to:
/opt/retropie/configs/all/joyhelp/xdrv.log


# Important
NOTE: These scripts will make changes to /etc/rc.local
your original will be copied to: /etc/rc.local.bakup

NOTE: These scripts will replace any runcommand-onstart.sh / runcommand-onend.sh scripts you may have setup. You will want to make backups of these files (if they exist on your system) before installing.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
	