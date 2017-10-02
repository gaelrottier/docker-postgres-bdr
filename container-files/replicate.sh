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

log "Configurating PostgreSQL ${PG_MAJOR} BDR Cluster"

oc config set-cluster http://kubernetes.default

pod=$(oc get pod --selector=app=$APP_NAME --no-headers | grep -v $HOSTNAME | sort -R  | awk '$3 == "Running" {print $1;exit}')
namespace=$(cat /var/run/secrets/kubernetes.io/serviceaccount/namespace)
service=$(oc get svc --selector=app=$APP_NAME --no-headers | awk '{print $1;exit}')
host="${service}.${namespace}.svc.cluster.local"
connectionString="port=5432 dbname=${POSTGRES_DB} user=${POSTGRES_USER} password=${POSTGRES_PASSWORD}"

log "Creating extensions..."
psql $POSTGRES_DB -U $POSTGRES_USER -c "
  CREATE EXTENSION IF NOT EXISTS btree_gist;
  CREATE EXTENSION IF NOT EXISTS bdr;"

# First node created by StatefulSet, becomes first master
# If $pod is not empty, other nodes exist, so it means the cluster is already set up
if [ -z "$pod" -o "$HOSTNAME" == "$APP_NAME-0" ]; then

  # First node creates the cluster
  log "First node in the cluster, creating server group..."
  psql $POSTGRES_DB -U $POSTGRES_USER -c "
    SELECT bdr.bdr_group_create(
      local_node_name := '${HOSTNAME}',
      node_external_dsn := 'host=${HOSTNAME}.${host} ${connectionString}'
    );"

else

  log "The cluster already exists, joining server group..."
  log "Sleep 10 sec waiting for server group creation..."
  sleep 10

  psql $POSTGRES_DB -U $POSTGRES_USER -c "
    SELECT bdr.bdr_group_join(
      local_node_name := '${HOSTNAME}',
      node_external_dsn := 'host=${HOSTNAME}.${host} ${connectionString}',
      join_using_dsn := 'host=${pod}.${host} ${connectionString}'
    );"

fi

log "Waiting for other nodes to be ready..."
psql $POSTGRES_DB -U $POSTGRES_USER -c "SELECT bdr.bdr_node_join_wait_for_ready();"


log "Configuration done !"
