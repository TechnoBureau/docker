#!/bin/sh
mkdir $WORKDIR/bin/
curl -sS https://getcomposer.org/installer | php -- --install-dir=$WORKDIR/bin --filename=composer
# curl -L "https://getcomposer.org/download/latest-stable/composer.phar" -o $WORKDIR/bin/composer
chmod +x $WORKDIR/bin/composer

sed -i '/include=\/etc\/php-fpm\.d\/\*\.conf/{h;d}; $G' $CHROOT/etc/php-fpm.conf
