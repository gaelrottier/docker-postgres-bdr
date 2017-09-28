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

  log "Configurating PostgreSQL ${PG_MAJOR} BDR Cluster"

  log "Sleep 10 sec..."
  sleep 10

  oc config set-cluster http://kubernetes.default

  # grep -v = not matches
  pod=$(oc get pod --selector=app=$APP_NAME --no-headers | grep -v $HOSTNAME | sort -R  | awk '$3 == "Running" {print $1;exit}')
  namespace=$APP_NAME
  service=$(oc get svc --selector=app=$APP_NAME --no-headers | awk '{print $1;exit}')

  if [ "$pod" ]; then

    log "Creating extensions..."
    psql $POSTGRES_DB -U $POSTGRES_USER -c "
      CREATE EXTENSION IF NOT EXISTS btree_gist;
      CREATE EXTENSION IF NOT EXISTS bdr;"

    if [ "$pod" == $HOSTNAME ]; then
    
        log "First node in the cluster, creating server group..."
        psql $POSTGRES_DB -U $POSTGRES_USER -c "
          SELECT bdr.bdr_group_create(
            local_node_name := '${HOSTNAME}',
            node_external_dsn := 'host=${HOSTNAME}.${service}.${namespace}.svc.cluster.local port=5432 dbname=${POSTGRES_DB} user=${POSTGRES_USER} password=${POSTGRES_PASSWORD}'
          );"

    else

        log "The cluster already exists, joining server group..."
        psql $POSTGRES_DB -U $POSTGRES_USER -c "
          SELECT bdr.bdr_group_join(
            local_node_name := '${HOSTNAME}',
            node_external_dsn := 'host=${HOSTNAME}.${service}.${namespace}.svc.cluster.local port=5432 dbname=${POSTGRES_DB} user=${POSTGRES_USER} password=${POSTGRES_PASSWORD}',
            join_using_dsn := 'host=${pod}.${service}.${namespace}.svc.cluster.local port=5432 dbname=${POSTGRES_DB} user=${POSTGRES_USER} password=${POSTGRES_PASSWORD}'
          );"

    fi

    log "Waiting for other nodes to be ready..."
    psql $POSTGRES_DB -U $POSTGRES_USER -c "SELECT bdr.bdr_node_join_wait_for_ready();"

  fi

  log "Configuration done !"

fi
