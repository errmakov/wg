#!/bin/bash

# Update package list and install necessary packages
sudo apt update
sudo apt install wireguard qrencode iptables-persistent ufw -y net-tools

# Get external interface from system info
EXT_IF=$(ip route get 8.8.8.8 | awk '{print $5}')

# Generate private and public keys
umask 077
wg genkey | tee privatekey | wg pubkey > publickey
PRIVATE_KEY=$(cat privatekey)

# Create WireGuard configuration file
sudo tee /etc/wireguard/wg0.conf << EOF
[Interface]
PrivateKey = oOiqDoBKZOOmGXs14UuKVJYw1CFAme++ubsvpwtRH1E=
Address = 10.1.1.1/24
ListenPort = 51820

PostUp = ufw route allow in on wg0 out on ens3
PostUp = iptables -t nat -I POSTROUTING -o ens3 -j MASQUERADE
PostUp = ip6tables -t nat -I POSTROUTING -o ens3 -j MASQUERADE

PreDown = ufw route delete allow in on wg0 out on ens3
PreDown = iptables -t nat -D POSTROUTING -o ens3 -j MASQUERADE
PreDown = ip6tables -t nat -D POSTROUTING -o ens3 -j MASQUERADE

[Peer]
PublicKey = WqoXM4P/WS2ENX2goFNyO7Lx2Ckr1L7LgaQBs4vO5lU=
AllowedIPs = 10.1.1.0/24
EOF

# Enable IP forwarding
sudo sysctl -w net.ipv4.ip_forward=1
sudo sysctl -w net.ipv6.conf.all.forwarding=1

# Configure UFW firewall to allow WireGuard and SSH traffic
sudo ufw allow 51820/udp
sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow https

# Start the WireGuard interface
sudo wg-quick up wg0

# Enable UFW firewall and ensure it starts on boot
sudo ufw enable
sudo systemctl enable ufw

# Enable the WireGuard service to start on boot
sudo systemctl enable wg-quick@wg0.service

# Echo the public key of the server
Echo "The public key of the server is:"
cat publickey

echo "WireGuard VPN set up successfully!"
echo "Going reboot"
sudo reboot