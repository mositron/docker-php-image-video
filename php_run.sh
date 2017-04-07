#!/bin/bash

rm -rf /etc/php-fpm.d/www.conf
cat <<EOF >> /etc/php-fpm.d/www.conf
[www]
user = webmaster
group = webmaster

listen = 127.0.0.1:$PHP_PORT
listen.allowed_clients = 127.0.0.1

pm = dynamic
pm.max_children = 100
pm.start_servers = 5
pm.min_spare_servers = 5
pm.max_spare_servers = 50

pm.status_path = $PHP_STATUS_URL

slowlog = /var/log/php-fpm/www-slow.log
request_slowlog_timeout = 5m
request_terminate_timeout = 10m

chdir = /var/www

clear_env = no

php_flag[display_errors] = on
php_admin_value[error_log] = /var/log/php-fpm/error.log
php_admin_flag[log_errors] = on
php_admin_value[memory_limit] = 512M

php_value[session.save_handler] = files
php_value[session.save_path]    = /tmp
php_value[soap.wsdl_cache_dir]  = /var/lib/php/wsdlcache
EOF

chown -R webmaster:webmaster /var/www

php-fpm -F
