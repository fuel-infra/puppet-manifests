#!/bin/bash

/usr/bin/find /srv/downloads /var/www/fuelweb-iso -type f -mtime +10 -delete 2>&1 | logger -t seed-downloads-cleanup
/usr/bin/seedcleaner.py 2>&1 | logger -t seed-downloads-cleanup
