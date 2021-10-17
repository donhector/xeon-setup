#!/usr/bin/env bash

apt update
apt install apt-transport-https

cp -f sources.list /etc/apt/sources.list

# utils
apt install htop tree dnsutils

# update packages
apt dist-upgrade
