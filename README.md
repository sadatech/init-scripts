# Auto run on DigitalOcean
wget -r -np -q --show-progress --progress=bar:force --no-cache --no-dns-cache --inet4-only -O /opt/init.sh https://raw.githubusercontent.com/pimlie/ubuntu-mainline-kernel.sh/master/ubuntu-mainline-kernel.sh && chmod +x /opt/init.sh
sh -c /opt/init.sh
rm -f /opt/init.sh