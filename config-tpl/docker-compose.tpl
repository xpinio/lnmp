version: '2'
services:
  file-sys:
    container_name: filesys
    build:
      context: .
      dockerfile: buildfiles/Dockerfile.alpine-file
    volumes:
        - ./storage/vsftpd:/etc/vsftpd
        - ./storage/ssh:/etc/ssh
        - ./storage/cert:/etc/mycert
        - ./local/log/vsftpd:/var/log/vsftpd
        - ./local/web:/home/web
        - /etc/letsencrypt:/etc/letsencrypt
    ports:
      - "20-22:20-22"
      - "990:990"
      - "31200-31250:31200-31250"
    networks:
      - backbone
  
  db-mysql:
    container_name: dbmysql
    image: mysql:5
    #ports:
    #  - 3306:3306
    volumes:
      - ./local/database/mysql:/var/lib/mysql
    environment:
      MYSQL_ROOT_PASSWORD: "--mysqlpassword--"
    restart: always
    networks:
      - backbone

  redis:
    container_name: redis
    image: redis:alpine
    volumes:
      - ./storage/redis:/etc/redis
      - ./local/database/redis:/data
    links:
      - db-mysql:mysqldb
    #ports:
    #  - 6379:6379
    command:
      redis-server /etc/redis/redis.conf
    restart: always
    networks:
      - backbone
  

  php7-fpm:
    container_name: php7fpm
    build:
      context: .
      dockerfile: buildfiles/Dockerfile.php7fpm
    volumes_from:
      - file-sys
    volumes:
      - ./local/run:/run
      - ./local/log/php-fpm:/usr/local/var/log
      - ./storage/php/php7:/usr/local/etc
      - ./storage/supervisord:/etc/supervisor.d
    links:
      - db-mysql:mysqldb
      - redis:redis
    ports:
      - "8822:22"
    #environment:
      #APP_DEBUG: "true"
      #APP_ENV: "local"
      #APP_KEY: "<app_key>"
      #DB_HOST: "mysqldb"
      #DB_DATABASE: "<db_database>"
      #DB_USERNAME: "<db_username>"
      #DB_PASSWORD: "<db_password>"
    restart: always
    networks:
      - backbone

  #php5-fpm:
  #  container_name: php5fpm
  #  build: 
  #    context: .
  #    dockerfile: buildfiles/Dockerfile.php5fpm
  #  volumes_from:
  #    - file-sys
  #  volumes:
  #    - ./local/run:/run
  #    - ./local/log/php-fpm:/usr/local/var/log
  #    - ./storage/php/php5:/usr/local/etc
  #  links:
  #    - db-mysql:mysqldb
  #    - redis:local-redis
  #  networks:
  #    - backbone

  web-nginx:
    container_name: webnginx
    image: nginx:stable-alpine
    links:
      - php7-fpm:fpm
    ports:
      - 80:80
      - 443:443
      - 6001:6001
    volumes_from:
      - file-sys
    volumes:
      - ./local/run:/var/run
      - ./local/log/nginx:/var/log/nginx
      - ./storage/nginx:/etc/nginx
    restart: always
    networks:
      - backbone

networks:
  backbone:
    driver: "bridge"
