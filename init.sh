#!/usr/bin/env bash
#
# one line script
#
set -eu

# Detect OS
OS_OUTPUT=$(cat /etc/*release)
if echo $OS_OUTPUT | grep -q "CentOS" ; then
    SERVER_OS="RHEL"
elif echo $OS_OUTPUT | grep -q "Ubuntu" ; then
    SERVER_OS="DEB"
else
    echo -e "Unsupported OS Installed."
    echo -e "Installation exited!"
    exit 1
fi

# Install package
if $SERVER_OS == "DEB" ; then
    apt -y update
    apt -y upgrade
    apt -f install
    apt -y install fail2ban util-linux zram-config nodejs npm
elif $SERVER_OS == "RHEL" ; then
    yum -y update
    yum -y upgrade
    dnf -y install fail2ban nodejs npm
fi

# end dev
exit 1

# Change default port SSHD
sed -i 's/#Port 22/Port 2222/g' /etc/ssh/sshd_config
sed -i 's/#HostKey \/etc\/ssh\/ssh_host_rsa/HostKey \/etc\/ssh\/ssh_host_rsa/g' /etc/ssh/sshd_config
sed -i 's/#HostKey \/etc\/ssh\/ssh_host_ecdsa/HostKey \/etc\/ssh\/ssh_host_ecdsa/g' /etc/ssh/sshd_config

# Configure SSH key
ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key
ssh-keygen -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key
ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N ''

# Allow 2222 SSHD port
ufw allow 2222
systemctl restart sshd

# Install update & upgrade
apt -y update
apt -y upgrade

# Install fail2ban
apt -y install fail2ban

# Configure fail2ban
echo "[sshd]" > /etc/fail2ban/jail.local
echo "enabled = true" >> /etc/fail2ban/jail.local
echo "port = ssh" >> /etc/fail2ban/jail.local
echo "filter = sshd" >> /etc/fail2ban/jail.local
echo "logpath = /var/log/auth.log" >> /etc/fail2ban/jail.local
echo "maxretry = 3" >> /etc/fail2ban/jail.local
echo "findtime = 300" >> /etc/fail2ban/jail.local
echo "bantime = 3600" >> /etc/fail2ban/jail.local
echo "ignoreip = 127.0.0.1" >> /etc/fail2ban/jail.local
systemctl enable fail2ban

# Register sysctl.conf
echo "kernel.randomize_va_space=1" >> /etc/sysctl.conf
echo "kernel.unprivileged_userns_clone=1" >> /etc/sysctl.conf
echo "net.ipv4.conf.all.accept_source_route=0" >> /etc/sysctl.conf
echo "net.ipv4.conf.all.forwarding=0" >> /etc/sysctl.conf
echo "net.ipv6.conf.all.disable_ipv6=1" >> /etc/sysctl.conf
echo "net.ipv6.conf.default.disable_ipv6=1" >> /etc/sysctl.conf
echo "net.ipv6.conf.lo.disable_ipv6=1" >> /etc/sysctl.conf
echo "net.ipv4.conf.all.accept_redirects=0" >> /etc/sysctl.conf
echo "net.ipv4.conf.all.secure_redirects=0" >> /etc/sysctl.conf
echo "net.ipv4.conf.all.send_redirects=0" >> /etc/sysctl.conf
echo "net.ipv4.conf.all.rp_filter=1" >> /etc/sysctl.conf
echo "net.ipv4.icmp_echo_ignore_all=0" >> /etc/sysctl.conf
echo "net.ipv4.conf.all.log_martians=1" >> /etc/sysctl.conf
echo "net.ipv4.icmp_echo_ignore_broadcasts=1" >> /etc/sysctl.conf
sysctl -p

# Configure NodeJS & NPM
npm update -g
npm install -g n
/usr/local/bin/n stable

# Install PM2
npm install -g pm2