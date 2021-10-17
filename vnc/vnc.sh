#!/usr/bin/env bash

sudo apt install tigervnc-standalone-server tigervnc-common

vncserver -verbose -localhost no -rfbport 5900

sudo ufw allow 5900/tcp


# List all sessions
vncserver -list 

# Stop all sessions
vncserver -kill :* -verbose -clean

