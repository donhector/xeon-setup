#!/usr/bin/env bash

sudo apt update
sudo apt install apt-transport-https software-properties-common

sudo cp -f sources.list /etc/apt/sources.list

# utils
sudo apt update
sudo apt install htop tree dnsutils curl wget unzip

# update packages
sudo apt dist-upgrade
