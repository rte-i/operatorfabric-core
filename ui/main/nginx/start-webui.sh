#!/bin/sh

# Copyright (c) 2018-2026, RTE (http://www.rte-france.com)
# See AUTHORS.txt
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
# SPDX-License-Identifier: MPL-2.0
# This file is part of the OperatorFabric project.

: '
  If the resolver is not indicated in the nginx conf, there could be side-effects (url not reachable). To solve this we must indicate
  the IP address available in the /etc/resolv.conf file. Given that this address can change between containers, it must be indicated
  dynamically => this is the purpose of this file
  The nginx.conf file is copied from /etc/nginx to the personal configuration directory and the default.conf file is copied from
  /etc/nginx/conf.d to <personal configuration directory>/conf.d. Then nginx is run by indicating as the config directory the
  personal configuration directory.
  The personal configuration directory is OPFAB_NGINX_CONF_DIR if set, else /personal-conf when running as root (historical
  behaviour) or /tmp/personal-conf when running as a non-root user (e.g. nginx UID 101 with a read-only root filesystem,
  /tmp being a writable volume).
  The container will be run by running this file
'

if [ "$(id -u)" = "0" ]; then
    default_personal_conf="/personal-conf"
else
    default_personal_conf="/tmp/personal-conf"
fi

# all nameservers of /etc/resolv.conf, IPv6 addresses between brackets as expected by nginx
export resolver=$(awk '$1 == "nameserver" { printf "%s%s", sep, ($2 ~ /:/ ? "[" $2 "]" : $2); sep = " " }' /etc/resolv.conf)
resolver_replace="resolver $resolver ipv6=off;"
resolver_replaced=".*resolver.*"
nginx_conf_path_default="/etc/nginx"
nginx_conf_path_personal="${OPFAB_NGINX_CONF_DIR:-$default_personal_conf}"
defaultconf_default="$nginx_conf_path_default/conf.d/default.conf"
defaultconf_personal="$nginx_conf_path_personal/conf.d/default.conf"

printenv | grep resolver
echo "running as: $(id)"
echo "resolver_replace: $resolver_replace"
echo "resolver_replaced: $resolver_replaced"
echo "nginx_conf_path_default: $nginx_conf_path_default"
echo "nginx_conf_path_personal: $nginx_conf_path_personal"
echo "defaultconf_default: ${defaultconf_default}"
echo "defaultconf_personal: ${defaultconf_personal}"

mkdir -p "$nginx_conf_path_personal/conf.d"

if grep -qe "$resolver_replaced" "$defaultconf_default"
then
    sed "s/$resolver_replaced/$resolver_replace/" "$defaultconf_default" > "$defaultconf_personal"
else
    sed "1i $resolver_replace" "$defaultconf_default" > "$defaultconf_personal"
fi

echo "The resolver in the personal default.conf:"
grep -e "$resolver_replaced" "$defaultconf_personal"

sed "s|$nginx_conf_path_default/conf\.d|$nginx_conf_path_personal/conf.d|" \
    "$nginx_conf_path_default/nginx.conf" > "$nginx_conf_path_personal/nginx.conf"

echo "The conf.d path in the personal nginx.conf file:"
grep "conf.d" "$nginx_conf_path_personal/nginx.conf"

# crond (logrotate of /var/log/nginx) needs root; a non-root image logs to stdout/stderr
if [ "$(id -u)" = "0" ] && [ -x /usr/sbin/crond ]; then
    /usr/sbin/crond
else
    echo "crond not started (not root or not installed)"
fi

# exec: nginx replaces the shell and receives the stop signal (graceful shutdown)
exec nginx -c "$nginx_conf_path_personal/nginx.conf" -g "daemon off;"
