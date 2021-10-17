#!/usr/bin/env bash

sudo apt update
sudo apt install -y python3-distutils
wget https://bootstrap.pypa.io/get-pip.py
python3 get-pip.py

# Debian does not seem to include ~/.local/bin in the path
# so we need this in ~/.bashrc

# export PATH="$HOME/.local/bin:$PATH"
