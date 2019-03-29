FROM php:7.2-fpm-alpine3.9
MAINTAINER "Stexine" <stexine@gmail.com>

#use aliyun mirrors for chinese server
#RUN echo "http://mirrors.aliyun.com/alpine/v3.9/main" > /etc/apk/repositories
#RUN echo "http://mirrors.aliyun.com/alpine/v3.9/community" >> /etc/apk/repositories

ENV TZ Asia/Shanghai

RUN apk add --update --no-cache --virtual .build-deps build-base gcc autoconf libtool \
      && apk add --no-cache openldap-dev krb5-dev icu-dev libmcrypt-dev freetype-dev imagemagick-dev gmp-dev tzdata acl openssh git bash \
                            libjpeg-turbo-dev libpng-dev imap-dev libxml2-dev libmemcached-dev nodejs-npm supervisor \
      && mkdir -p /usr/local/etc/php/conf.d \
      && docker-php-ext-configure imap --with-imap-ssl --with-kerberos \
      && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
      && docker-php-ext-install ldap intl pdo_mysql mysqli exif sockets gd imap zip json mbstring xmlrpc bcmath gmp opcache \
      && pecl install redis xdebug-2.7.0 imagick \
      && docker-php-ext-enable redis xdebug imagick \
      && apk del .build-deps

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone \
      && wget https://getcomposer.org/installer -O /tmp/composer-setup.php \
      && php /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer \
      && rm /tmp/composer-setup.php \
      && addgroup -g 5000 vuser \
      && adduser -h /home/web -s /bin/bash -u 5001 web -G vuser -D \
      && echo "web:--webpassword--" | chpasswd

RUN echo 'supervisord -c /etc/supervisord.conf' > /run.sh && \
    # echo '/usr/sbin/sshd -f /etc/ssh/sshd_config' > /run.sh && \
    echo 'php-fpm' >> /run.sh && \
    chmod u+x /run.sh

WORKDIR /home/web

ENTRYPOINT ["/bin/sh", "/run.sh"]
