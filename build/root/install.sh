#!/bin/bash

# exit script if return code != 0
set -e

# build scripts
####

# download build scripts from github
curl --connect-timeout 5 --max-time 600 --retry 5 --retry-delay 0 --retry-max-time 60 -o /tmp/scripts-master.zip -L https://github.com/binhex/scripts/archive/master.zip

# unzip build scripts
unzip /tmp/scripts-master.zip -d /tmp

# move shell scripts to /root
mv /tmp/scripts-master/shell/arch/docker/*.sh /usr/local/bin/

# detect image arch
####

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

# pacman packages
####

# define pacman packages
pacman_packages="xorg-fonts-misc xorg-server-xvfb tigervnc python2-xdg lxappearance xcompmgr python-pip python-numpy ttf-dejavu terminus-font ttf-dejavu cantarell-fonts gnu-free-fonts"

# install compiled packages using pacman
if [[ ! -z "${pacman_packages}" ]]; then
	pacman -S --needed $pacman_packages --noconfirm
fi

# aur packages
####

# define aur packages
aur_packages="dwm-distrotube-git dmenu2 surf st novnc hsetroot ttf-font-awesome"

# call aur install script (arch user repo)
source aur.sh

# python packages
####

pip install websockify PyXDG

# config - look and feel
####

# download gtk icon theme (dark)
# curly.sh -of "/tmp/gtk-icon.zip" -url "https://github.com/binhex/themes/raw/master/gtk/icon-themes/BLACK-Ice-Numix-FLAT_1.4.1.zip"

# unpack gtk icon theme to home dir
# unzip -d "/home/nobody/.icons/" "/tmp/gtk-icon.zip"

# download gtk widget theme (light)
# curly.sh -of "/tmp/gtk-widget-light.zip" -url "https://github.com/binhex/themes/raw/master/gtk/widget-theme/Ultimate-Maia-Blue-light-v3.34.zip"

# download gtk widget theme (dark)
# curly.sh -of "/tmp/gtk-widget-dark.zip" -url "https://github.com/binhex/themes/raw/master/gtk/widget-theme/Ultimate-Maia-Blue-dark-v3.34.zip"

# unpack gtk widget theme to home dir
# unzip -d "/home/nobody/.themes/" "/tmp/gtk-widget-light.zip"
# unzip -d "/home/nobody/.themes/" "/tmp/gtk-widget-dark.zip"

# copy gtk-3.0 settings to home directory (sets gtk widget and icons)
mkdir -p /home/nobody/.config/gtk-3.0
cp /home/nobody/.build/gtk/config/settings.ini /home/nobody/.config/gtk-3.0/settings.ini

# copy settings to home directory (sets openbox theme and fonts)
#mkdir -p /home/nobody/.config/openbox
#cp /home/nobody/.build/openbox/config/rc.xml /home/nobody/.config/openbox/rc.xml

# copy settings to home directory (sets tint2 theme)
#mkdir -p /home/nobody/.config/tint2/theme
#cp /home/nobody/.build/tint2/theme/tint2rc /home/nobody/.config/tint2/theme/tint2rc

# config - novnc
####

# replace all novnc normal (used for bookmarks and favorites) icon sizes with fixed 16x16 icon
sed -i -E 's~\s+<link rel="icon" sizes.*~    <link rel="icon" sizes="16x16" type="image/png" href="app/images/icons/novnc-16x16.png">~g' "/usr/share/webapps/novnc/vnc.html"

# replace all novnc home screen (used for tablets etc) icon sizes with fixed 16x16 icon
sed -i -E 's~\s+<link rel="apple-touch-icon" sizes.*~    <link rel="apple-touch-icon" sizes="16x16" type="image/png" href="app/images/icons/novnc-16x16.png">~g' "/usr/share/webapps/novnc/vnc.html"

# set a background color for openbox (slightly lighter than default to contrast taskbar)
#cat <<'EOF' > /home/nobody/.config/openbox/autostart
#BG=""
#if which hsetroot >/dev/null 2>/dev/null; then
#  BG=hsetroot
#elif which esetroot >/dev/null 2>/dev/null; then
#  BG=esetroot
#elif which xsetroot >/dev/null 2>/dev/null; then
#  BG=xsetroot
#fi
#test -z $BG || $BG -solid "#4d4d4d"
#EOF

# env vars
####

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

# replace env vars placeholder string with contents of file (here doc)
# note we need to -reinsert the placeholder as other gui docker images
# may require additonal env vars i.e. krusader
sed -i '/# ENVVARS_PLACEHOLDER/{
	s/# ENVVARS_PLACEHOLDER//g
	r /tmp/envvars_heredoc
}' /usr/local/bin/init.sh
rm /tmp/envvars_heredoc

# container perms
####

# define comma separated list of paths 
install_paths="/home/nobody"

# split comma separated string into list for install paths
IFS=',' read -ra install_paths_list <<< "${install_paths}"

# process install paths in the list
for i in "${install_paths_list[@]}"; do

	# confirm path(s) exist, if not then exit
	if [[ ! -d "${i}" ]]; then
		echo "[crit] Path '${i}' does not exist, exiting build process..." ; exit 1
	fi

done

# convert comma separated string of install paths to space separated, required for chmod/chown processing
install_paths=$(echo "${install_paths}" | tr ',' ' ')

# set permissions for container during build - Do NOT double quote variable for install_paths otherwise this will wrap space separated paths as a single string
chmod -R 775 "${install_paths}"

# set ownership back to user 'nobody', required after copying of configs and themes
chown -R nobody:users "${install_paths}"

# cleanup
# cleanup.sh
