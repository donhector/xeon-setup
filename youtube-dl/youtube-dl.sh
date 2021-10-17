#!/usr/bin/env bash

sudo apt install ffmpeg
pip install --user --upgrade youtube-dl

# Example to pull m3u8 
#youtube-dl --all-subs -f mp4 -o download.mp4 https://d3kzbcfhipx62u.cloudfront.net/0829e466-c2a7-4acf-9356-f90f0a3cb5ce/hls/413.m3u8
