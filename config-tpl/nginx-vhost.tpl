server {
    listen          80;
    server_name     --host--.--domain--;
    root            /home/web/wwwroot/--domain--/--host--;

    #charset koi8-r;

    #access_log      /var/log/nginx/--domain--.access.log;
    error_log       /var/log/nginx/--domain--.error.log;
    rewrite_log     on;

    location / {
        index  index.php index.html index.htm;
        try_files $uri $uri/ /index.php?/$request_uri;
    }

    #error_page  404              /404.html;

    # redirect server error pages to the static page /50x.html
    #
    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   html;
    }


    # pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000
    #
    location ~ \.php$ {
        #fastcgi_pass   unix:/var/run/php7fpm.sock;
	fastcgi_pass	fpm:9000;
        fastcgi_index  index.php;
        fastcgi_param  SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include        fastcgi_params;
    }

    # deny access to .htaccess files, if Apache's document root
    # concurs with nginx's one
    #
    location ~ /\.ht {
        deny  all;
    }
}

# HTTPS server
#
server {
    listen          443 ssl;
    server_name     --host--.--domain--;
    root            /home/web/wwwroot/--domain--/--host--;

    client_body_in_file_only clean;
    client_body_buffer_size 128K;
    client_max_body_size 50M;

    #access_log      /var/log/nginx/--domain--.access.log;
    error_log       /var/log/nginx/--domain--.error.log;
    rewrite_log     on;    
    

    #ssl_certificate     /etc/letsencrypt/live/--host--.--domain--/fullchain.pem;
    #ssl_certificate_key /etc/letsencrypt/live/--host--.--domain--/privkey.pem;
    ssl_certificate     /etc/mycert/nginx.crt;
    ssl_certificate_key /etc/mycert/nginx.key;
    ssl_protocols       TLSv1 TLSv1.1 TLSv1.2;
    ssl_ciphers         HIGH:!aNULL:!MD5;

    # ----------------- v2ray ------------------------
    location /publ {
        proxy_redirect off;
        proxy_pass http://antiwall:12085;
	    proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $http_host;
    }
    # -------------------------------------------------
    
    # -------------- phpmyadmin --------------
    location /dbadmin {
    	alias /home/web/share/dbadmin;
	location ~ .php$ {
		include /etc/nginx/fastcgi_params;
		fastcgi_index index.php;
		fastcgi_read_timeout 3600s;
		fastcgi_param  SCRIPT_FILENAME  $request_filename;
		if (-f $request_filename) {
		    fastcgi_pass fpm:9001;
		}
	}

	location ~ ^/(.*\.(eot|otf|woff|ttf|css|js|jpg|jpeg|gif|png|ico|zip|tgz|gz|rar|bz2|xls|tar|bmp))$ {
	    expires 30d;
	    log_not_found off;
            access_log off;
	}
    }
    # -------------- end phpmyadmin ------------------

    # serve static files directly
    location ~* \.(jpg|jpeg|gif|css|png|js|ico|html|eot|ttf|woff|svg|woff2|otf)$ {
        #allow access to static content from foreign host
        add_header Access-Control-Allow-Origin *;
        access_log off;
        log_not_found off;
        expires max;
    }

    index index.php;

    location / {
        try_files $uri $uri/ /index.php$is_args$args;
    }

    # --------------------  laravel app settings -----------------------------

    #location ^~ /xbackx {
    #    alias /home/web/app/xbackx/current/public;
    #    try_files $uri $uri/ @xbackx;
    #    location ~ \.php$ {
    #        include /etc/nginx/fastcgi_params;
    #        fastcgi_pass fpm:9001
    #        fastcgi_param SCRIPT_FILENAME $request_filename;
    #    }
    #}

    #location @xbackx {
    #    rewrite /xbackx/(.*)$ /xbackx/index.php?/$1 last;
    #}

    # -------------------- end laravel app settings --------------------------

    # pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000
    #
    location ~ \.php$ {
        fastcgi_pass   fpm:9000; #production use 9001, dev use 9000
        #fastcgi_pass   unix:/var/run/php7fpm.prod.sock; #production sock with opcache, dev use php7fpm.sock
        fastcgi_index  index.php;
        fastcgi_param  SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include        fastcgi_params;
        fastcgi_split_path_info                 ^(.+\.php)(/.+)$;
        fastcgi_param PATH_INFO                 $fastcgi_path_info;
        fastcgi_param PATH_TRANSLATED           $document_root$fastcgi_path_info;
    }

    # deny access to .htaccess files, if Apache's document root
    # concurs with nginx's one
    #
    #location ~ /\.ht {
    #    access_log off;
    #   log_not_found off; 
    #   deny  all;
    #}

    location ~ /\. {
        access_log off;
        log_not_found off; 
        deny all;
    }

}
