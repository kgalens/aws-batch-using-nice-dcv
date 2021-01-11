FROM amazonlinux:latest as dcv

# Prepare the container to run systemd inside
ENV container docker

ARG AWS_REGION=us-east-1

# Install tools
RUN yum -y install tar sudo less vim lsof firewalld net-tools pciutils \
                   file wget kmod xz-utils ca-certificates binutils kbd \
                   python3-pip bind-utils jq bc bzip2

# Install awscli and configure region only
# Note: required to run aws ssm command
RUN pip3 install awscli 2>/dev/null \
 && mkdir $HOME/.aws \
 && echo "[default]" > $HOME/.aws/config \
 && echo "region =  ${AWS_REGION}" >> $HOME/.aws/config \
 && chmod 600 $HOME/.aws/config

# Install X server and GNOME desktop
RUN yum -y install gdm gnome-session gnome-classic-session gnome-session-xsession \
	xorg-x11-server-Xorg xorg-x11-fonts-Type1 xorg-x11-drivers  \
	gnome-terminal gnu-free-fonts-common gnu-free-mono-fonts gnu-free-sans-fonts gnu-free-serif-fonts

# Configure Xorg, install NICE DCV server
RUN rpm --import https://s3-eu-west-1.amazonaws.com/nice-dcv-publish/NICE-GPG-KEY \
 && mkdir -p /tmp/dcv-inst \
 && cd /tmp/dcv-inst \
 && wget -qO- https://d1uj6qtbmh3dt5.cloudfront.net/2020.0/Servers/nice-dcv-2020.0-8428-el7.tgz |tar xfz - --strip-components=1 \
 && yum -y install \
    nice-dcv-gl-2020.0.759-1.el7.i686.rpm \
    nice-dcv-gltest-2020.0.229-1.el7.x86_64.rpm \
    nice-dcv-gl-2020.0.759-1.el7.x86_64.rpm \
    nice-dcv-server-2020.0.8428-1.el7.x86_64.rpm \
    nice-xdcv-2020.0.296-1.el7.x86_64.rpm

# Install firefox
RUN cd /opt \
 && wget -qO- /opt/firefox.tar.bz2 "https://download.mozilla.org/?product=firefox-latest&os=linux64&lang=en-US" | tar xjf -

# Define the dcvserver.service
COPY dcvserver.service /usr/lib/systemd/system/dcvserver.service

# Start DCV server and initialize level 5
COPY run_script.sh /usr/local/bin/

# Send Notification message DCV session ready
COPY send_dcvsessionready_notification.sh /usr/local/bin/

# Open required port on firewall, create test user, send notification, start DCV session for the user
COPY startup_script.sh /usr/local/bin

# Copy the firefox init script
COPY firefox_init.sh /usr/local/bin

# Append the startup script to be executed at the end of initialization and fix permissions
RUN echo "/usr/local/bin/startup_script.sh" >> "/etc/rc.local" \
 && chmod +x "/etc/rc.local" "/usr/local/bin/run_script.sh" \
             "/usr/local/bin/send_dcvsessionready_notification.sh" \
             "/usr/local/bin/startup_script.sh" \
	     "/usr/local/bin/firefox_init.sh"

EXPOSE 8443

CMD ["/usr/local/bin/run_script.sh"]
