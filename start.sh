#!/bin/bash

set -eu -o pipefail

cd /app/code/seafile-server-latest

read

# first run
if ! [ -e  /app/data ]; then
    echo "=> First run create /app/data"
    mkdir -p /app/data

    echo "=> Setup seafile"
    ./setup-seafile.sh auto -n Seafile -i ${APP_ORIGIN}
fi

echo "=> Start seafile"
./seafile.sh start

echo "=> Start seahub"
./seahub.sh start-fastcgi

echo "=> Start nginx"
nginx