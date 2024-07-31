#!/bin/bash

set -e

echo "Starting server configuration..."

# Function to check and configure network settings
configure_network() {
    echo "Configuring network..."
    NETPLAN_FILE="/etc/netplan/00-installer-config.yaml"
    HOSTS_FILE="/etc/hosts"

    # Update netplan configuration
    if ! grep -q "192.168.16.21/24" $NETPLAN_FILE; then
        cat <<EOT > $NETPLAN_FILE
network:
  ethernets:
    eth0:
      dhcp4: false
      addresses: [192.168.16.21/24]
  version: 2
EOT
        netplan apply
        echo "Netplan configuration updated."
    else
        echo "Netplan configuration already set."
    fi

    # Update /etc/hosts
    if ! grep -q "192.168.16.21 server1" $HOSTS_FILE; then
        sed -i '/server1/d' $HOSTS_FILE
        echo "192.168.16.21 server1" >> $HOSTS_FILE
        echo "/etc/hosts updated."
    else
        echo "/etc/hosts already set."
    fi
}

# Function to install software
install_software() {
    echo "Installing software..."
    apt-get update

    # Install apache2 if not already installed
    if ! dpkg -l | grep -q apache2; then
        apt-get install -y apache2
        echo "apache2 installed."
    else
        echo "apache2 already installed."
    fi

    # Install squid if not already installed
    if ! dpkg -l | grep -q squid; then
        apt-get install -y squid
        echo "squid installed."
    else
        echo "squid already installed."
    fi
}

# Function to configure firewall
configure_firewall() {
    echo "Configuring firewall..."
    ufw allow from 192.168.16.0/24 to any port 22
    ufw allow http
    ufw allow 3128

    if ! ufw status | grep -q "Status: active"; then
        ufw enable
        echo "ufw enabled."
    else
        echo "ufw already enabled."
    fi
}

# Function to configure user accounts
configure_users() {
    echo "Configuring user accounts..."

    declare -A users
    users=(
        ["dennis"]="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG4rT3vTt99Ox5kndS4HmgTrKBT8SKzhK4rhGkEVGlCI student@generic-vm"
        ["aubrey"]=""
        ["captain"]=""
        ["snibbles"]=""
        ["brownie"]=""
        ["scooter"]=""
        ["sandy"]=""
        ["perrier"]=""
        ["cindy"]=""
        ["tiger"]=""
        ["yoda"]=""
    )

    for user in "${!users[@]}"; do
        if id "$user" &>/dev/null; then
            echo "User $user already exists."
        else
            useradd -m -s /bin/bash "$user"
            echo "User $user created."
        fi

        mkdir -p /home/$user/.ssh
        chown $user:$user /home/$user/.ssh
        chmod 700 /home/$user/.ssh

        if [[ -n "${users[$user]}" ]]; then
            echo "${users[$user]}" > /home/$user/.ssh/authorized_keys
        fi

        chown $user:$user /home/$user/.ssh/authorized_keys
        chmod 600 /home/$user/.ssh/authorized_keys

        echo "SSH keys configured for $user."

        if [ "$user" == "dennis" ]; then
            usermod -aG sudo dennis
            echo "User $user granted sudo access."
        fi
    done
}

# Main execution
configure_network
install_software
configure_firewall
configure_users

echo "Server configuration complete."
