#!/bin/sh
set -eu
export TERM=xterm
# Bash Colors
green=`tput setaf 2`
bold=`tput bold`
reset=`tput sgr0`
log() {
  if [[ "$@" ]]; then echo "${bold}${green}[LOG `date +'%T'`]${reset} $@";
  else echo; fi
}

message() {
  echo "========================================================================"
  echo "    You can now connect to this PostgreSQL Server using:                "
  echo "    psql -U $POSTGRES_USER -W $POSTGRES_PASSWORD -h<host> --port $POSTGRES_PORT"
  echo "                                                                        "
  echo "    For security reasons, you might want to change the above password.  "
  echo "============================================s============================"
}

sleep 5
while true; do
  for f in /var/lib/postgresql/data/pg_log/postgresql*.log; do 
    if [ -f $f ]; then
      if grep "database system is ready to accept connections" $f; then 
        break 2;
      else
        sleep 1;
      fi
    fi
  done;
done

if [[ "$APP_NAME" != "" ]]; then

  oc config set-cluster http://kubernetes.default

  # grep -v = not matches
  # tac = reverse cat to join nodes with highest possible index to avoid joining only first one
  pod=$(oc get pod --selector=app=$APP_NAME --no-headers | grep -v $HOSTNAME | tac | awk '{print $1;exit}')
  namespace=$(oc get namespace $APP_NAME --no-headers | awk '{print $1;exit}')
  service=$(oc get svc --selector=app=$APP_NAME --no-headers | awk '{print $1;exit}')

  if [ "$pod" ]; then

    psql $POSTGRES_DB -U $POSTGRES_USER -c "
      CREATE EXTENSION IF NOT EXISTS btree_gist;
      CREATE EXTENSION IF NOT EXISTS bdr;"

    if [ "$pod" == $HOSTNAME ]; then
    
        psql $POSTGRES_DB -U $POSTGRES_USER -c "
          SELECT bdr.bdr_group_create(
            local_node_name := '${HOSTNAME}',
            node_external_dsn := 'host=${HOSTNAME}.${service}.${namespace}.svc.cluster.local port=5432 dbname=${POSTGRES_DB} user=${POSTGRES_USER} password=${POSTGRES_PASSWORD}'
          );"

    else

        psql $POSTGRES_DB -U $POSTGRES_USER -c "
          SELECT bdr.bdr_group_join(
            local_node_name := '${HOSTNAME}',
            node_external_dsn := 'host=${HOSTNAME}.${service}.${namespace}.svc.cluster.local port=5432 dbname=${POSTGRES_DB} user=${POSTGRES_USER} password=${POSTGRES_PASSWORD}',
            join_using_dsn := 'host=${pod}.${service}.${namespace}.svc.cluster.local port=5432 dbname=${POSTGRES_DB} user=${POSTGRES_USER} password=${POSTGRES_PASSWORD}'
          );"

        psql $POSTGRES_DB -U $POSTGRES_USER -c "SELECT bdr.bdr_node_join_wait_for_ready();"

    fi

  fi

fi
