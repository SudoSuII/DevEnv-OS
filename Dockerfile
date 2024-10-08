FROM archlinux:latest

# additional files
##################

# add supervisor conf file for app
ADD build/*.conf /etc/supervisor/conf.d/

# add install bash script
ADD build/root/*.sh /root/

# add bash script to run deluge
ADD run/nobody/*.sh /home/nobody/

# add pre-configured config files for nobody
ADD config/nobody/ /home/nobody/.build/

# Add custom pacman.conf
ADD build/root/pacman.conf /etc/pacman.conf

# install app
#############

# set nobody to use bash (allowing login)
RUN su -s /bin/bash nobody

# make executable and run bash scripts to install app
RUN chmod +x /root/*.sh && \
	/bin/bash /root/install.sh

# docker settings
#################

# map /config to host defined config path (used to store configuration from app)
VOLUME /config

# expose port for vnc client (direct connection)
EXPOSE 5900

# expose port for novnc (web interface)
EXPOSE 6080

# env
#####

# set environment variables for user nobody
ENV HOME /home/nobody

# set environment variable for terminal
ENV TERM st

# set environment variables for language
ENV LANG en_GB.UTF-8
