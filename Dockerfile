FROM cloudron/base:0.10.0
MAINTAINER Seafile Developers <support@cloudron.io>

ENV VERSION="6.0.9"
ENV TARBALL="seafile-server_${VERSION}_x86-64.tar.gz"

RUN mkdir -p /app/code
WORKDIR /app/code

RUN apt-get update && \
    apt-get install python && \
    apt-get install -y python2.7 libpython2.7 python-setuptools python-imaging python-ldap python-urllib3 sqlite3 && \
    rm -r /var/cache/apt /var/lib/apt/lists

COPY seafile.conf /etc/nginx/sites-enabled/seafile.conf
RUN rm /etc/nginx/sites-enabled/default

RUN wget https://bintray.com/artifact/download/seafile-org/seafile/${TARBALL}
RUN tar -xzf ${TARBALL}
RUN mkdir installed
RUN mv ${TARBALL} installed
RUN ln -s seafile-server-${VERSION} seafile-server-latest

RUN ln -s /app/data/ccnet ccnet && \
    ln -s /app/data/conf conf && \
    ln -s /app/data/seafile-data seafile-data

ADD start.sh seafile.conf /app/code/
RUN rm /app/code/seafile-server-latest/check_init_admin.py
ADD check_init_admin.py /app/code/seafile-server-latest
RUN rm /app/code/seafile-server-latest/setup-seafile.sh
ADD setup-seafile.sh /app/code/seafile-server-latest

EXPOSE 80

CMD ["/app/code/start.sh"]
