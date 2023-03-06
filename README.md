# Init script new VPS 

## DigitalOcean
```sh
#!/bin/bash
wget -r -np -q --show-progress --progress=bar:force --no-cache --no-dns-cache --inet4-only -O /opt/init.sh https://raw.githubusercontent.com/sadatech/init-scripts/master/init.sh && chmod +x /opt/init.sh && sh -c /opt/init.sh && rm -f /opt/init.sh
```
