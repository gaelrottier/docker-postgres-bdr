FROM openshift/base-centos7

ENV \
      GOSU_VERSION=1.10 \
      PG_VERSION=94 \
      PG_MAJOR=9.4 \
      PGDATA=/var/lib/pgsql/data \
      OC_VERSION=3.6.0

USER root

RUN \
  set -ex; \
  yum install -y http://packages.2ndquadrant.com/postgresql-bdr${PG_VERSION}-2ndquadrant/yum-repo-rpms/postgresql-bdr${PG_VERSION}-2ndquadrant-redhat-latest.noarch.rpm ; \
  yum update -y yum-skip-broken ; \
  yum install -y postgresql-bdr${PG_VERSION}-bdr ; \
  \
  yum clean all ; \
  rm -rf /var/cache/yum

RUN \
  set -ex; \
  mkdir -p /var/run/postgresql ; \
  mkdir -p $PGDATA ; \
  \
  fix-permissions /var/run/postgresql ; \
  fix-permissions $PGDATA ; \
  fix-permissions /opt/app-root/ ; \
  \
  chown -R postgres:postgres $PGDATA ; \
  chown -R postgres:postgres /opt/app-root ; \
  \
  curl -o /usr/local/bin/gosu -SL "https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/gosu-amd64" ; \
  chmod +x /usr/local/bin/gosu ; \
  \
  outdir="openshift-origin-client-tools-v${OC_VERSION}-c4dd4cf-linux-64bit" ; \
  curl -sSL "https://github.com/openshift/origin/releases/download/v${OC_VERSION}/${outdir}.tar.gz" | tar -zxvf - ; \
  cp $outdir/oc /usr/bin ; \
  chmod +x /usr/bin/oc ; \
  rm -rf $outdir


ADD postgresql-entrypoint.sh /
ADD replicate.sh /docker-entrypoint-initdb.d/

RUN chmod +x /postgresql-entrypoint.sh && \
    chmod +x /docker-entrypoint-initdb.d/replicate.sh

ENV PATH /usr/pgsql-${PG_MAJOR}/bin:$PATH

EXPOSE 5432

USER postgres

ENTRYPOINT [ "/postgresql-entrypoint.sh" ]

CMD ["postgres"]
