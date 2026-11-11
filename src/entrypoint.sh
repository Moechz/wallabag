#!/bin/sh
# TOS wrapper: the upstream image runs Apache on :80 as root. Wallabag only
# needs a writable data dir and PHP, so serve it with the PHP built-in server
# as the image's own `nobody` user on 8080.
set -u
set -e
cd /var/www/wallabag
mkdir -p data/db web/assets/images
envsubst < /etc/wallabag/parameters.template.yml > app/config/parameters.yml
if [ ! -s data/db/wallabag.sqlite ]; then
  php bin/console wallabag:install --env=prod -n
fi
exec php -S 0.0.0.0:8080 -t web web/app.php
