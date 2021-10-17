#!/usr/bin/env bash

set -eu

sudo apt update
sudo apt install ufw

# Status
sudo ufw status verbose

# Enable
sudo ufw enable

# Disable
#sudo ufw disable

# Example to open port 80
#sudo ufw allow 80/tcp

# Example to open RDP port for machine in my lan
#sudo ufw allow from 192.168.1.0/24 to any 3389/tcp

