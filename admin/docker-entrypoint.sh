#!/bin/sh
set -e
htpasswd -bc /etc/nginx/.htpasswd "${ADMIN_USER}" "${ADMIN_PASS}"
exec nginx -g "daemon off;"