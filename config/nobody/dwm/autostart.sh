#! /bin/bash

# Run XCompMgr (required for transparency support)

xcompmgr &

# Set Wallpaper

feh --bg-center "/home/nobody/.themes/wallpaper.png" &

# Java fix for DWM
# https://wiki.gentoo.org/wiki/Dwm#Blank_.28grey.29_windows_of_Java_applications_.28such_as_netbeans.29

wmname LG3D &
xsetroot -solid black &

# Launch DMenu

dmenu_run &