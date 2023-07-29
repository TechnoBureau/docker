#!/bin/sh

cd $WORKDIR
cp -R /tmp/app/* .
if [ ! -f composer.json ]; then
  rm -Rf tmp/
  $WORKDIR/bin/composer create-project "symfony/skeleton 6.3.*" tmp --stability="stable" --prefer-dist --no-progress --no-interaction --no-install

  cd tmp
  $WORKDIR/bin/composer require "php:>=8.1"
  $WORKDIR/bin/composer config --json extra.symfony.docker 'true'
  cp -Rp . ..
  cd -

  rm -Rf tmp/
fi

if [ -f composer.json ]; then
$WORKDIR/bin/composer install --prefer-dist --no-dev --no-autoloader --no-scripts --no-progress;
$WORKDIR/bin/composer clear-cache;
fi

mkdir -p $CHROOT/var/cache $CHROOT/var/log;
if [ -f composer.json ]; then
cp /tmp/app/.env $WORKDIR/.env
$WORKDIR/bin/composer dump-autoload --classmap-authoritative --no-dev;
$WORKDIR/bin/composer dump-env prod;
$WORKDIR/bin/composer run-script --no-dev post-install-cmd;
chmod +x $WORKDIR/bin/console;
fi

# Alternative
#sed '/include=.*/{h;d}; $G' $CHROOT/etc/php-fpm.conf

#sed -i 's|^\(error_log = \).*$|\1/proc/self/fd/2|' $CHROOT/etc/php-fpm.conf
#sed -i 's|^\(pid = \).*$|\1/opt/technobureau/php-fpm.pid|' $CHROOT/etc/php-fpm.conf
#sed -i 's|^\(daemonize = \).*$|\1 no|' $CHROOT/etc/php-fpm.conf
