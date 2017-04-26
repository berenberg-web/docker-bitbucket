#!/usr/bin/env bash

# Config for sendmail
echo -e "$(hostname -i)\t$(hostname) $(hostname).localhost" >> /etc/hosts

# Start sendmail service in background
service sendmail restart &

# Forward any CMD command
exec "$@"