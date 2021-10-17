#!/usr/bin/env bash

set -eu

sudo apt install -y curl jq

curl -fsSL https://get.docker.com | sudo sh

# Allow non privileged user
sudo usermod -aG docker $USER

# Install docker-compose
sudo rm -f /usr/local/bin/docker-compose
VERSION=$(curl --silent https://api.github.com/repos/docker/compose/releases/latest | jq .name -r)
sudo curl -L "https://github.com/docker/compose/releases/download/${VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-composer

# Alternatively, it can be installed/upgraded with "pip3 install docker-compose --user -U"
