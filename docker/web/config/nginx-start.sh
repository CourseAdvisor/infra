#!/bin/sh
sed -i "s/%fpm-ip%/$FPM_PORT_9000_TCP_ADDR/" /etc/nginx/conf.d/courseadvisor.conf
nginx "-g" "daemon off;"
