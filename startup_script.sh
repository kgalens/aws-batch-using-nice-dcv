#!/bin/bash
firewall-cmd --zone=public --permanent --add-port=8443/tcp
firewall-cmd --reload
/usr/local/bin/send_dcvsessionready_notification.sh >/dev/null 2>&1 &
_username="$(aws secretsmanager get-secret-value --secret-id \
                   dcv-cred-user --query SecretString  --output text)"
adduser "${_username}" -G wheel
echo "${_username}:$(aws secretsmanager get-secret-value --secret-id \
                   dcv-cred-passwd --query SecretString --output text)" | chpasswd
/bin/dcv create-session --owner "${_username}" --user "${_username}" "${_username}session" --init /usr/local/bin/firefox_init.sh
/bin/dcv set-display-layout --session "${_username}session" 1900x1080+0+0

