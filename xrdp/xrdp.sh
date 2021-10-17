#!/usr/bin/env bash

set -eu

sudo apt install -y xorgxrdp xrdp

sudo usermod -a -G ssl-cert xrdp

#sudo sed -i 's/=console/=anybody/g' /etc/X11/Xwrapper.config
#sudo sed -i 's/AllowRootLogin=true/AllowRootLogin=false/g' /etc/xrdp/sesman.ini

#sudo vim /etc/xrdp/startwm.sh 
## unset DBUS_SESSION_ADDRESS
## unset XDG_RUNTIME_DIR
## source ${HOME}/.profile

# Allow regular user to create color device. Fixes authentication prompts on login
sudo bash -c "cat >/etc/polkit-1/localauthority/50-local.d/45-allow.colord.pkla" <<EOF
[Allow Colord all Users]
Identity=unix-user:*
Action=org.freedesktop.color-manager.create-device;org.freedesktop.color-manager.create-profile;org.freedesktop.color-manager.delete-device;org.freedesktop.color-manager.delete-profile;org.freedesktop.color-manager.modify-device;org.freedesktop.color-manager.modify-profile
ResultAny=no
ResultInactive=no
ResultActive=yes
EOF

#echo gnome-session > ~/.xsession
#chmod +x ~/.xsession

# For some reason could not get it working with Gnome's default 'gdm3' even
# after editing /etc/gdm3/daemon.conf and uncommenting 'WaylandEnable=false'
# so went with 'lightdm' instead:
sudo apt install lightdm
sudo dpkg-reconfigure lightdm

# Configure lightdm so it lists users in the login screen
sudo sed -i 's/^#greeter-hide-users=.*/greeter-hide-users=false/g' /etc/lightdm/lightdm.conf

# xrdp only allows one X session for the user, so if the user is already logged into a local Xsession, the remote will fail
# Configure the OS just give us a shell on boot, and not the GUI (ie 'graphical.target')
sudo systemctl set-default multi-user.target

# Restart xrdp so changes in config files are applied
sudo systemctl restart xrdp 
sudo systemctl status xrdp 

# Open firewall only for incoming lan connections on 3389
iface=$(ip route | grep default | cut -d ' ' -f5)
network=$(ip route | grep -E "0/.*${iface}" | cut -d ' ' -f1)
sudo ufw allow from ${network} to any port 3389
sudo ufw reload

