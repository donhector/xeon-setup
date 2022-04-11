#!/usr/bin/env bash

set -eu

sudo apt update
sudo apt install --no-install-recommends -y \
  cockpit \
  cockpit-machines \
  cockpit-docker \
  cockpit-storaged \
  cockpit-netwrokmanager \
  cockpit-pcp \

sudo systemctl start cockpit
sudo systemctl status cockpit

sudo netstat -pnltu | grep 9090
sudo ufw allow 9090/tcp
sudo ufw reload
