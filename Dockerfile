FROM cloudron/base:0.3.0
MAINTAINER Seafile Developers <support@cloudron.io>

RUN apt-get update
RUN apt-get install -y python2.7 python-setuptools python-imaging python-mysqldb sqlite3

RUN mkdir -p /app/code
WORKDIR /app/code

ENV VERSION="4.2.1"
ENV TARBALL="seafile-server_${VERSION}_x86-64.tar.gz"
ENV SEAFILE_DATA_DIR="/app/data/seafile-data"
ENV SEAHUB_DATA_DIR="/app/data/seahub-data"

RUN mkdir -p ${SEAFILE_DATA_DIR}
RUN mkdir -p ${SEAHUB_DATA_DIR}

# http://manual.seafile.com/deploy/using_mysql.html
RUN wget https://bitbucket.org/haiwen/seafile/downloads/${TARBALL}
RUN tar -xzf ${TARBALL}
RUN mkdir installed
RUN mv ${TARBALL} installed

EXPOSE 8000

# seafile.sh and seahub.sh want the data folders to be ../ from the code
# RUN sed -i "s/TOPDIR=.*/TOPDIR=\/app\/data\//" "/app/code/seafile-server-${VERSION}/seafile.sh"
# RUN sed -i "s/TOPDIR=.*/TOPDIR=\/app\/data\//" "/app/code/seafile-server-${VERSION}/seahub.sh"

ADD create-admin.py /app/code/create-admin.py
ADD start.sh /app/code/start.sh

CMD [ "/app/code/start.sh" ]