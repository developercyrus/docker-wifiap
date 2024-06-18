#!/bin/bash

# Check if WIFI_INTERFACE and OUTGOING_INTERFACE environment variables are set
if [ -z "$WIFI_INTERFACE" ] || [ -z "$OUTGOING_INTERFACE" ]; then
    echo "WIFI_INTERFACE and OUTGOING_INTERFACE environment variables must be set."
    exit 1
fi

# Enable IP forwarding
sysctl -w net.ipv4.ip_forward=1

# Bring up the wireless interface
ifconfig $WIFI_INTERFACE up

# Configure network interface
ifconfig $WIFI_INTERFACE up 172.16.10.1 netmask 255.255.255.0

# list out interface
ifconfig

# list route table
ip route

# set iw
iw reg set US

# check iw
iw reg get

# Capture the default gateway
DEFAULT_GATEWAY=$(ip route | grep 'default via' | awk '{print $3}')

CONTAINER_VERSION=$(sed -n 's/^VERSION_ID="\([0-9.]*\)"/\1/p' /etc/os-release)
echo $CONTAINER_VERSION



# Ensure you're using the same version of iptables within your container that your host is using. If your host is using iptables-legacy, then your container should also use iptables-legacy.
if [[ $(printf '%s\n' "$CONTAINER_VERSION" "$HOST_VERSION" | sort -V | head -n 1) != "$HOST_VERSION" ]] ; then
  if [[ "$CONTAINER_VERSION" == "$HOST_VERSION" ]]; then
    echo "$CONTAINER_VERSION is equal to $HOST_VERSION"
    IPTABLES_CMD="/usr/sbin/iptables"
  else
    echo "$CONTAINER_VERSION is less than $HOST_VERSION"
    IPTABLES_CMD="/usr/sbin/iptables"
  fi
else
  echo "$CONTAINER_VERSION is greater than $HOST_VERSION"
  IPTABLES_CMD="/usr/sbin/iptables-legacy"
fi


# Clean up existing iptables rules to avoid conflicts
#iptables -t nat -F
#iptables -F

# Set up NAT with iptables
#iptables -t nat -A POSTROUTING -o $OUTGOING_INTERFACE -j MASQUERADE
#iptables -A FORWARD -i $WIFI_INTERFACE -o $OUTGOING_INTERFACE -j ACCEPT
#iptables -A FORWARD -i $OUTGOING_INTERFACE -o $WIFI_INTERFACE -m state --state RELATED,ESTABLISHED -j ACCEPT

# Clean up existing iptables rules to avoid conflicts
#$IPTABLES_CMD -t nat -F
#$IPTABLES_CMD -F

# Set up NAT with iptables
$IPTABLES_CMD -t nat -C POSTROUTING -o $OUTGOING_INTERFACE -j MASQUERADE || $IPTABLES_CMD -t nat -A POSTROUTING -o $OUTGOING_INTERFACE -j MASQUERADE
$IPTABLES_CMD -C FORWARD -i $WIFI_INTERFACE -o $OUTGOING_INTERFACE -j ACCEPT || $IPTABLES_CMD -A FORWARD -i $WIFI_INTERFACE -o $OUTGOING_INTERFACE -j ACCEPT
$IPTABLES_CMD -C FORWARD -i $OUTGOING_INTERFACE -o $WIFI_INTERFACE -m state --state RELATED,ESTABLISHED -j ACCEPT || $IPTABLES_CMD -A FORWARD -i $OUTGOING_INTERFACE -o $WIFI_INTERFACE -m state --state RELATED,ESTABLISHED -j ACCEPT

# Debugging: Print current iptables rules
echo "Current iptables NAT rules:"
#iptables -t nat -L -v -n
$IPTABLES_CMD -t nat -L -v -n

echo "Current iptables FORWARD rules:"
#iptables -L FORWARD -v -n
$IPTABLES_CMD -L FORWARD -v -n

# Replace placeholder in hostapd.conf
sed -i "s/\$WIFI_INTERFACE/$WIFI_INTERFACE/g" /etc/hostapd/hostapd.conf
sed -i "s/\$WIFI_INTERFACE/$WIFI_INTERFACE/g" /etc/dnsmasq.conf
sed -i "s/\$DEFAULT_GATEWAY/$DEFAULT_GATEWAY/g" /etc/dnsmasq.conf

# list config
cat /etc/hostapd/hostapd.conf
cat /etc/dnsmasq.conf

# Start hostapd
#hostapd -dd /etc/hostapd/hostapd.conf &
hostapd /etc/hostapd/hostapd.conf &

# Start dnsmasq
dnsmasq -C /etc/dnsmasq.conf -d --port=5353


