#!/bin/bash
set -e

CONF_URL="https://raw.githubusercontent.com/fotexnet/Public-scripts/main/Zabbix/AgentUpdate/zabbix_agent.conf"
CONF_FILE="/etc/zabbix/zabbix_agent2.conf"

# Prompt for values
read -rp "Enter Zabbix Server IP (passive): " SERVER_IP
read -rp "Enter Zabbix ServerActive IP: " SERVER_ACTIVE_IP
read -rp "Enter Hostname for this agent: " HOSTNAME

# Download base config
echo "Downloading base config..."
curl -fsSL "$CONF_URL" -o "$CONF_FILE"

# Modify values in config
echo "Updating configuration..."
sed -i "s/^Server=.*/Server=$SERVER_IP/" "$CONF_FILE"
sed -i "s/^ServerActive=.*/ServerActive=$SERVER_ACTIVE_IP/" "$CONF_FILE"
sed -i "s/^Hostname=.*/Hostname=$HOSTNAME/" "$CONF_FILE"

# Detect CentOS (check /etc/centos-release or ID in os-release)
if [ -f /etc/centos-release ] || grep -qi "centos" /etc/os-release; then
    echo "CentOS detected. Applying iptables rules..."
    iptables -I INPUT -p tcp --dport 10050 -m state --state NEW -j ACCEPT
    iptables -A OUTPUT -p tcp -d "$SERVER_IP" --dport 10051 -j ACCEPT
    sudo sh -c '/sbin/iptables-save > /etc/sysconfig/iptables'
fi

# Restart agent
echo "Restarting Zabbix Agent 2..."
systemctl restart zabbix-agent2

echo "Done. Zabbix agent configured with:"
echo "  Server=$SERVER_IP"
echo "  ServerActive=$SERVER_ACTIVE_IP"
echo "  Hostname=$HOSTNAME"
