#!/bin/bash

# Based on and with thanks to Binhex.

# Exit script if return code != 0

set -e

##############################################################################################################################################################################################################
# Download build scripts from GitHub
##############################################################################################################################################################################################################

curl --connect-timeout 5 --max-time 600 --retry 5 --retry-delay 0 --retry-max-time 60 -o /tmp/scripts-master.zip -L https://github.com/rcannizzaro/scripts/archive/master.zip

# Unzip build scripts

unzip /tmp/scripts-master.zip -d /tmp

# Move shell scripts to /root

mv /tmp/DevEnv-Scripts-master/shell/arch/docker/*.sh /usr/local/bin/

##########################################################################################################################################################################################################################
# Detect image architecture
##########################################################################################################################################################################################################################

OS_ARCH=$(cat /etc/os-release | grep -P -o -m 1 "(?=^ID\=).*" | grep -P -o -m 1 "[a-z]+$")
if [[ ! -z "${OS_ARCH}" ]]; then
	if [[ "${OS_ARCH}" == "arch" ]]; then
		OS_ARCH="x86-64"
	else
		OS_ARCH="aarch64"
	fi
	echo "[info] OS_ARCH defined as '${OS_ARCH}'"
else
	echo "[warn] Unable to identify OS_ARCH, defaulting to 'x86-64'"
	OS_ARCH="x86-64"
fi

##########################################################################################################################################################################################################################
# Pacman Packages
##########################################################################################################################################################################################################################

# Define pacman packages

pacman_packages="xorg-fonts-misc xorg-server-xvfb tigervnc python2-xdg lxappearance xcompmgr python-pip python-numpy openssh feh ttf-ibm-plex ttf-dejavu terminus-font ttf-dejavu cantarell-fonts gnu-free-fonts wmname"

# Install compiled packages using pacman, updating database for Multilib support.

if [[ ! -z "${pacman_packages}" ]]; then
	pacman -Sy --needed $pacman_packages --noconfirm
fi

##########################################################################################################################################################################################################################
# AUR Packages
##########################################################################################################################################################################################################################

# Define AUR packages

aur_packages="surf st novnc hsetroot ttf-font-awesome"

# Call AUR Install Script

source aur.sh

# Python Packages (needed for Curly?)

pip install websockify PyXDG

##########################################################################################################################################################################################################################
# GIT & MakePkg Builds
##########################################################################################################################################################################################################################

# Move into main directory

cd /home/nobody/

# Get and build DMenu from source

git clone https://github.com/rcannizzaro/DevEnv-DistroTube-DMenu.git
cd DevEnv-DistroTube-DMenu
sudo make clean install

# Get and build DWM from source

git clone https://github.com/rcannizzaro/DevEnv-DistroTube-DWM.git
cd DevEnv-DistroTube-DWM
sudo make clean install

##########################################################################################################################################################################################################################
# GTK / Wallpaper / Themes
##########################################################################################################################################################################################################################

# Get Wallpaper

mkdir -p /home/nobody/.themes
curly.sh -of "/home/nobody/.themes/wallpaper.png" -url "https://raw.githubusercontent.com/rcannizzaro/DevEnv-Themes/master/wallpaper.png"

# Copy gtk-3.0 settings to home directory (sets gtk widget and icons)

mkdir -p /home/nobody/.config/gtk-3.0
cp /home/nobody/.build/gtk/config/settings.ini /home/nobody/.config/gtk-3.0/settings.ini

# Copy DWM autostart

mkdir -p /home/nobody/.dwm/
cp /home/nobody/.build/dwm/autostart.sh /home/nobody/.dwm/autostart.sh

##########################################################################################################################################################################################################################
# NoVNC Configuration
##########################################################################################################################################################################################################################

# Replace all NoVNC normal (used for bookmarks and favorites) icon sizes with fixed 16x16 icon

sed -i -E 's~\s+<link rel="icon" sizes.*~    <link rel="icon" sizes="16x16" type="image/png" href="app/images/icons/novnc-16x16.png">~g' "/usr/share/webapps/novnc/vnc.html"

# Replace all NoVNC home screen (used for tablets etc) icon sizes with fixed 16x16 icon

sed -i -E 's~\s+<link rel="apple-touch-icon" sizes.*~    <link rel="apple-touch-icon" sizes="16x16" type="image/png" href="app/images/icons/novnc-16x16.png">~g' "/usr/share/webapps/novnc/vnc.html"

##########################################################################################################################################################################################################################
# Environment Variables
##########################################################################################################################################################################################################################

cat <<'EOF' > /tmp/envvars_heredoc
export WEBPAGE_TITLE=$(echo "${WEBPAGE_TITLE}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')
if [[ ! -z "${WEBPAGE_TITLE}" ]]; then
	echo "[info] WEBPAGE_TITLE defined as '${WEBPAGE_TITLE}'" | ts '%Y-%m-%d %H:%M:%.S'
fi

export VNC_PASSWORD=$(echo "${VNC_PASSWORD}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')
if [[ ! -z "${VNC_PASSWORD}" ]]; then
	echo "[info] VNC_PASSWORD defined as '${VNC_PASSWORD}'" | ts '%Y-%m-%d %H:%M:%.S'
fi

# ENVVARS_PLACEHOLDER
EOF

# Replace environment variables placeholder string with contents of file (here doc)
# note we need to -reinsert the placeholder as other gui docker images
# may require additonal env vars i.e. krusader

sed -i '/# ENVVARS_PLACEHOLDER/{
	s/# ENVVARS_PLACEHOLDER//g
	r /tmp/envvars_heredoc
}' /usr/local/bin/init.sh
rm /tmp/envvars_heredoc

##########################################################################################################################################################################################################################
# Container Permissions
##########################################################################################################################################################################################################################

# Define comma separated list of paths 

install_paths="/home/nobody"

# Split comma separated string into list for install paths

IFS=',' read -ra install_paths_list <<< "${install_paths}"

# Process install paths in the list

for i in "${install_paths_list[@]}"; do

	# Confirm path(s) exist, if not then exit

	if [[ ! -d "${i}" ]]; then
		echo "[crit] Path '${i}' does not exist, exiting build process..." ; exit 1
	fi

done

# Convert comma separated string of install paths to space separated, required for chmod/chown processing

install_paths=$(echo "${install_paths}" | tr ',' ' ')

# Set permissions for container during build - Do NOT double quote variable for install_paths otherwise this will wrap space separated paths as a single string

chmod -R 775 "${install_paths}"

# Set ownership back to user 'nobody', required after copying of configs and themes

chown -R nobody:users "${install_paths}"

# cleanup
# cleanup.sh