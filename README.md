# Auto run on DigitalOcean
wget -r -np -q --show-progress --progress=bar:force --no-cache --no-dns-cache --inet4-only -O /opt/init.sh https://raw.githubusercontent.com/sadatech/init-scripts/master/init.sh && chmod +x /opt/init.sh && sh -c /opt/init.sh && rm -f /opt/init.shlibc.so.6: version `GLIBC_2.28' not found (required by node)