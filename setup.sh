#!/bin/bash

HOST=set-hostname
DOMAIN=set-domain
NGINX_CONF_DIR=./storage/nginx/conf.d

WEB_USER_PASSWORD=set-web-user-password
MYSQL_ROOT_PASSWORD=set-mysql-root-password

PHPMYADMIN_VERSION=4.8.5

DOCKER_COMPOSE_FILE=./docker-compose.yml
DOCKERFILE_ALPINE_FILE=./buildfiles/Dockerfile.alpine-file
DOCKERFILE_PHP7FPM=./buildfiles/Dockerfile.php7fpm

#generate ssh keys
ssh-keygen -f ./storage/ssh/ssh_host_rsa_key -N '' -t rsa
ssh-keygen -f ./storage/ssh/ssh_host_ecdsa_key -N '' -t dsa
ssh-keygen -f ./storage/ssh/ssh_host_ed25519_key -N '' -t ed25519

#generate nginx keys
openssl req -x509 -nodes -days 800 -newkey rsa:2048 -keyout ./storage/cert/nginx.key -out ./storage/cert/nginx.crt -config ./storage/cert/ssl-cert.conf

mkdir -p /var/local/data/local
ln -s /var/local/data/local/ ./local
cp ./local-structure/* ./local -R
mkdir -p ./local/web/wwwroot/$DOMAIN/$HOST
echo '<?php phpinfo(15); ?>' > ./local/web/wwwroot/$DOMAIN/$HOST/index.php

# get phpmyadmin
mkdir -p ./local/web/share
wget -c https://files.phpmyadmin.net/phpMyAdmin/$PHPMYADMIN_VERSION/phpMyAdmin-$PHPMYADMIN_VERSION-all-languages.tar.gz -O - | tar -xz -C ./local/web/share
mv ./local/web/share/phpMyAdmin-$PHPMYADMIN_VERSION-all-languages ./local/web/share/dbadmin
mkdir -p ./local/web/share/dbadmin/tmp
chmod 777 ./local/web/share/dbadmin/tmp -R
DBADMIN_BLOWFISH=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
sed -e "s/--blowfish--/$DBADMIN_BLOWFISH/" ./config-tpl/dbadmin-config.tpl > ./local/web/share/dbadmin/config.inc.php


# nginx
sed -e "s/--host--/$HOST/g; s/--domain--/$DOMAIN/g" ./config-tpl/nginx-vhost.tpl > $NGINX_CONF_DIR/$HOST.$DOMAIN.conf

# mysql
sed -e "s/--mysqlpassword--/$MYSQL_ROOT_PASSWORD/" ./config-tpl/docker-compose.tpl > $DOCKER_COMPOSE_FILE

# dockerfile alpine file system
sed -e "s/--webpassword--/$WEB_USER_PASSWORD/" ./config-tpl/docker-file.tpl > $DOCKERFILE_ALPINE_FILE

#dockerfile php7fpm
sed -e "s/--webpassword--/$WEB_USER_PASSWORD/" ./config-tpl/docker-php7fpm.tpl > $DOCKERFILE_PHP7FPM

#build
docker-compose up

exit 0
