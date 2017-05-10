FROM cloudron/base:0.10.0
MAINTAINER Seafile Developers <support@cloudron.io>

ENV VERSION="6.0.9"
ENV TARBALL="seafile-server_${VERSION}_x86-64.tar.gz"

RUN mkdir -p /app/code/installed
WORKDIR /app/code

RUN apt-get update && \
    apt-get install -y nginx-extras python2.7 libpython2.7 python-setuptools python-imaging python-ldap python-mysqldb python-memcache python-urllib3 && \
    rm -r /var/cache/apt /var/lib/apt/lists

RUN cd /app/code/installed && curl -L https://bintray.com/artifact/download/seafile-org/seafile/${TARBALL} | tar -xz --strip-components 1 -f -
RUN ln -s /app/data/conf /app/code/conf

ADD start.sh nginx.conf /app/code/
ADD setup-seafile.sh /app/code/installed/

CMD ["/app/code/start.sh"]
