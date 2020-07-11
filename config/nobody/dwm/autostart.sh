#! /bin/bash

# Run XCompMgr (required for transparency support)

xcompmgr &

# Set Wallpaper

feh --bg-center "/home/nobody/.themes/wallpaper.png" &

# Launch DMenu

dmenu_run &