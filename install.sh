#!/bin/sh

# Check if the script is running as root
if [ "$(id -u)" != "0" ]; then
    echo "Must run as root. Restarting with sudo..."
    # Re-execute the script with sudo
    sudo "$0" "$@"
    exit $?
fi

apt update

# Obtain the current username who invoked sudo
CURRENT_USER=${SUDO_USER:-$(whoami)}

# install GPIO for controlling relays and reading motion detectors
echo "==================================="
echo "===Installing General Purpose IO==="
echo "==================================="
apt install -y gpiod libgpiod-dev

# Create the gpio-users group
groupadd gpio-users

# Add the current user to the gpio-users group
usermod -aG gpio-users "$CURRENT_USER"

# Write the udev rule
echo 'KERNEL=="gpiochip*", OWNER="10001", GROUP="gpio-users", MODE="0660"' > /etc/udev/rules.d/99-gpiochip.rules

# Reload the udev rules
udevadm control --reload-rules
udevadm trigger

echo "User $CURRENT_USER added to gpio-users and udev rule set."
