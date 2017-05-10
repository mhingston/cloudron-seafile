#!/bin/bash

set -eu -o pipefail

cd /app/code/installed

read

# first run
if ! [ -e  /app/data/data ]; then
    echo "=> First run creating config directory"
    # mkdir -p /app/data/conf

    echo "=> Setup seafile"
    ./setup-seafile.sh auto -n Seafile -i ${APP_ORIGIN} -d /app/data/data -a /app/data/ccnet -b /app/data/conf -c /app/data/seahub.db
fi

echo "=> Start seafile"
./seafile.sh start

echo "=> Start seahub"
./seahub.sh start-fastcgi

echo "=> Start nginx"
nginx -c /app/code/nginx.conf
