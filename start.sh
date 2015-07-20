#!/bin/bash

set -eu -o pipefail

fqdn=$(hostname -f)

VERSION="4.2.1"
TARBALL="seafile-server_${VERSION}_x86-64.tar.gz"
INSTALL_PATH="/app/code/seafile-server-${VERSION}"
SEAFILE_LD_LIBRARY_PATH="${INSTALL_PATH}/seafile/lib/:${INSTALL_PATH}/seafile/lib64"
SEAFILE_DATA_DIR="/app/data/seafile-data"
SEAHUB_DATA_DIR="/app/data/seahub-data"

# first run
if [[ -z "$(ls -A /app/data)" ]]; then
    cd "/app/code/seafile-server-${VERSION}"

    LD_LIBRARY_PATH=${SEAFILE_LD_LIBRARY_PATH} ${INSTALL_PATH}/seafile/bin/ccnet-init --config-dir /app/data/ccnet --name "Seafile" --host ${fqdn} --port 10001
    LD_LIBRARY_PATH=${SEAFILE_LD_LIBRARY_PATH} ${INSTALL_PATH}/seafile/bin/seaf-server-init --seafile-dir ${SEAFILE_DATA_DIR} --port 12001 --fileserver-port 8082

    # Write seafile.ini
    echo "${SEAFILE_DATA_DIR}" > "/app/data/ccnet/seafile.ini"

    # Generate seafevents.conf
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

    # init db
    sqlite3 "/app/data/seahub.db" ".read ${INSTALL_PATH}/seahub/sql/sqlite3.sql"

    # setup avatars
    mv "${INSTALL_PATH}/seahub/media/avatars" "/app/data/seahub-data/avatars"
    ln -s ../../../seahub-data/avatars "${INSTALL_PATH}/seahub/media"

    # link latest seafile
    ln -s $(basename ${INSTALL_PATH}) "/app/data/seafile-server-latest"
fi

## TODO update fqdn and the likes

cd "/app/data/seafile-server-latest"

./seafile.sh start
./seahub.sh start

wait
