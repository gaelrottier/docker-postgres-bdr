FROM polinux/centos-supervisor
ENV \
      GOSU_VERSION=1.10 \
      PG_VERSION=94 \
      PG_MAJOR=9.4 \
      PGDATA=/var/lib/postgresql/data \
      TERM=xterm \
      OC_VERSION=3.6.0

RUN \
  set -ex; \
  rpm --rebuilddb ; \
  yum clean all ; \
  yum install -y  http://packages.2ndquadrant.com/postgresql-bdr${PG_VERSION}-2ndquadrant/yum-repo-rpms/postgresql-bdr${PG_VERSION}-2ndquadrant-redhat-latest.noarch.rpm ; \
  yum update -y yum-skip-broken ; \
  yum install -y postgresql-bdr${PG_VERSION}-bdr curl ; \
  yum clean all ; \
  curl -o /usr/local/bin/gosu -SL "https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/gosu-amd64" ; \
  chmod +x /usr/local/bin/gosu ; \
  mkdir -p /var/run/postgresql ; \
  chown -R postgres /var/run/postgresql; \
  \
  outdir="openshift-origin-client-tools-v${OC_VERSION}-c4dd4cf-linux-64bit" ; \
  curl -sSL "https://github.com/openshift/origin/releases/download/v${OC_VERSION}/${outdir}.tar.gz" | tar -zxvf - ; \
  cp $outdir/oc /usr/bin ; \
  chmod +x /usr/bin/oc ; \
  rm -rf $outdir ; \
  rm -rf /var/cache/yum 

COPY container-files/ /

ENV PATH /usr/pgsql-${PG_MAJOR}/bin:$PATH

VOLUME /var/lib/postgresql/data

EXPOSE 5432
