#!/bin/bash

set -eu -o pipefail

echo "==============="

fqdn=$(hostname -f)

VERSION="4.2.1"
TARBALL="seafile-server_${VERSION}_x86-64.tar.gz"
INSTALL_PATH="/app/data/seafile-server-${VERSION}"
SEAFILE_LD_LIBRARY_PATH="${INSTALL_PATH}/seafile/lib/:${INSTALL_PATH}/seafile/lib64"
SEAFILE_DATA_DIR="/app/data/seafile-data"
SEAHUB_DATA_DIR="/app/data/seahub-data"
CCNET_CONFIG_DIR="/app/data/ccnet"

# first run
if [[ -z "$(ls -A /app/data)" ]]; then
    # copy the code to /app/data/seafile-server-4.2.1 to have the same folder structure as recommended http://manual.seafile.com/deploy/using_sqlite.html
    cp -rf "/app/code/seafile-server-${VERSION}" ${INSTALL_PATH}

    echo "run ccnet-init"
    LD_LIBRARY_PATH=${SEAFILE_LD_LIBRARY_PATH} ${INSTALL_PATH}/seafile/bin/ccnet-init --config-dir ${CCNET_CONFIG_DIR} --name "Seafile" --host "${fqdn}" --port 10001

    echo "run seaf-server-init"
    LD_LIBRARY_PATH=${SEAFILE_LD_LIBRARY_PATH} ${INSTALL_PATH}/seafile/bin/seaf-server-init --seafile-dir ${SEAFILE_DATA_DIR} --port 12001 --fileserver-port 8082

    # Write seafile.ini
    echo "${SEAFILE_DATA_DIR}" > "/app/data/ccnet/seafile.ini"

    # Generate seafevents.conf
    mkdir -p "/app/data/conf"
    cat > "/app/data/conf/seafdav.conf" <<EOF
[WEBDAV]
enabled = false
port = 8080
fastcgi = false
host = 0.0.0.0
share_name = /
EOF

    # generate seahub/settings.py
    echo "SECRET_KEY = \"$(python2 ${INSTALL_PATH}/seahub/tools/secret_key_generator.py)\"" >> /app/data/seahub_settings.py
    echo "FILE_SERVER_ROOT = \"https://${fqdn}/seafhttp\"" >> /app/data/seahub_settings.py

    # init db
    echo "init the database"
    sqlite3 "/app/data/seahub.db" ".read ${INSTALL_PATH}/seahub/sql/sqlite3.sql"

    # setup avatars
    mkdir -p "/app/data/seahub-data/"
    mv "${INSTALL_PATH}/seahub/media/avatars" "/app/data/seahub-data/avatars"
    ln -s ../../../seahub-data/avatars "${INSTALL_PATH}/seahub/media"

    # link latest seafile into data for provide the recommended folder structure
    ln -s ${INSTALL_PATH} /app/data/seafile-server-latest


    # run it the first time to setup db
    cd "/app/data/seafile-server-latest"

    echo "Start seafile to setup the database"
    ./seafile.sh start
    echo "Done"

    # setup admin
    echo "Setup admin"
    python2 /app/code/create-admin.py ${CCNET_CONFIG_DIR} "admin@cloudron.io" "password"
    echo "Done"

    echo "Stop seafile to finalized the initial setup"
    ./seafile.sh stop
    echo "Done"

    # add ldap
cat >> "${CCNET_CONFIG_DIR}/ccnet.conf" <<EOF

[LDAP]
HOST = ldap://${LDAP_SERVER}:${LDAP_PORT}
BASE = ${LDAP_USERS_BASE_DN}
LOGIN_ATTR = mail
EOF

fi

# regenerate the nginx config
cp /app/code/seafile.conf.template /etc/nginx/sites-available/default
sed -e "s/##HOSTNAME##/${HOSTNAME}/" -i /etc/nginx/sites-available/default

sed -e "s/SERVICE_URL = .*/SERVICE_URL = https:\/\/${HOSTNAME}/" -i /app/data/ccnet/ccnet.conf

## TODO update fqdn, ldap and the likes

cd "${INSTALL_PATH}"

echo "Start seafile"
./seafile.sh start
echo "Done"

echo "Start seahub"
./seahub.sh start-fastcgi 8001
echo "Done"

echo "Start nginx"
service nginx start
echo "Done"

# this will just sit there and wait ;-)
read
