#!/usr/bin/env bash
#
# one line script
#
set -eu
DEBIAN_FRONTEND=noninteractive

# Detect OS
OS_OUTPUT=$(cat /etc/*release)
if echo $OS_OUTPUT | grep -q -E "CentOS Linux 7|CentOS Linux 8|AlmaLinux-8|Rocky Linux" ; then
    SERVER_OS="RHEL"
elif echo $OS_OUTPUT | grep -q -E "Ubuntu 18.04|Ubuntu 20.04|Ubuntu 20.10|Ubuntu 22.04" ; then
    SERVER_OS="DEB"
else
    echo -e "Unsupported OS Installed."
    echo -e "Installation exited!"
    exit 1
fi

# Install package
if [[ $SERVER_OS == "DEB" ]]; then
    apt -y update
    apt -y upgrade
    apt -y install fail2ban util-linux zram-config ca-certificates wget curl gnupg lsb-release neofetch

    # Install kernel-update
    if [[ ! -f /usr/local/bin/update-kernel ]]; then
        wget https://raw.githubusercontent.com/pimlie/ubuntu-mainline-kernel.sh/master/ubuntu-mainline-kernel.sh
        chmod +x ubuntu-mainline-kernel.sh
        sudo mv ubuntu-mainline-kernel.sh /usr/local/bin/update-kernel
        /usr/local/bin/update-kernel -i --yes

        # Fix package missing
        apt -f -y install
    fi

    # Docker install
    mkdir -m 0755 -p /etc/apt/keyrings
    if [[ ! -f /etc/apt/keyrings/docker.gpg ]]; then
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    fi
    if [[ ! -f /etc/apt/sources.list.d/docker.list ]]; then
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list
        apt -y update
        apt -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        systemctl enable docker
    fi

    # Configure date time
    timedatectl set-timezone Asia/Jakarta
    hostnamectl set-hostname sada-deploy
elif [[ $SERVER_OS == "RHEL" ]]; then
    yum -y update
    yum -y upgrade
    dnf -y install fail2ban nodejs npm
fi

# Change default port SSHD
sed -i 's/#Port 22/Port 2222/g' /etc/ssh/sshd_config
# sed -i 's/#HostKey \/etc\/ssh\/ssh_host_rsa/HostKey \/etc\/ssh\/ssh_host_rsa/g' /etc/ssh/sshd_config
# sed -i 's/#HostKey \/etc\/ssh\/ssh_host_ecdsa/HostKey \/etc\/ssh\/ssh_host_ecdsa/g' /etc/ssh/sshd_config

# Configure SSH key
# ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key
# ssh-keygen -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key
# ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N ''

# Allow 2222 SSHD port
if [[ $SERVER_OS == "DEB" ]]; then
    ufw allow 2222
fi
systemctl restart sshd

# Configure fail2ban
if [[ ! -f /etc/fail2ban/jail.local ]]; then
    echo "[sshd]" > /etc/fail2ban/jail.local
    echo "enabled = true" >> /etc/fail2ban/jail.local
    echo "port = ssh" >> /etc/fail2ban/jail.local
    echo "filter = sshd" >> /etc/fail2ban/jail.local
    echo "logpath = /var/log/auth.log" >> /etc/fail2ban/jail.local
    echo "maxretry = 3" >> /etc/fail2ban/jail.local
    echo "findtime = 300" >> /etc/fail2ban/jail.local
    echo "bantime = 3600" >> /etc/fail2ban/jail.local
    echo "ignoreip = 127.0.0.1" >> /etc/fail2ban/jail.local
fi

# Register sysctl.conf
rm -f /etc/sysctl.conf
if [[ ! -f /etc/sysctl.conf ]]; then
    echo "# Sysctlconf" > /etc/sysctl.conf
    echo "kernel.randomize_va_space=1" >> /etc/sysctl.conf
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
    echo "vm.swappiness=50" >> /etc/sysctl.conf
    echo "vm.vfs_cache_pressure=50" >> /etc/sysctl.conf
    sysctl -p
fi

# Add neofetch
echo "" >> /root/.bashrc
echo "clear" >> /root/.bashrc
echo "neofetch" >> /root/.bashrc

# End script
# Go shutdown mark is process done
init 0
