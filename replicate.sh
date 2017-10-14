#!/bin/sh
set -eux
export TERM=xterm
# Bash Colors
green=`tput setaf 2`
bold=`tput bold`
reset=`tput sgr0`
log() {
  if [[ "$@" ]]; then echo "${bold}${green}[LOG `date +'%T'`]${reset} $@";
  else echo; fi
}

log "Configuring PostgreSQL ${PG_MAJOR} BDR Cluster"

oc config set-cluster http://kubernetes.default

## Get oc details
pod=$(oc get pod --selector=app=$APP_NAME --no-headers | grep -v $HOSTNAME | sort -R  | awk '$3 == "Running" {print $1;exit}')
namespace=$(cat /var/run/secrets/kubernetes.io/serviceaccount/namespace)
service=$(oc get svc --selector=app=$APP_NAME --no-headers | awk '{print $1;exit}')
host="${service}.${namespace}.svc.cluster.local"
connectionString="port=5432 dbname=${POSTGRES_DB} user=${POSTGRES_USER} password=${POSTGRES_PASSWORD}"


log "Creating extensions..."
psql -U $POSTGRES_USER -c "
  CREATE EXTENSION IF NOT EXISTS btree_gist;
  CREATE EXTENSION IF NOT EXISTS bdr;"

# First node created by StatefulSet, becomes first master
if [ "$HOSTNAME" == "$APP_NAME-0" ]; then

  # First node creates the cluster
  log "First node in the cluster, creating server group..."

  psql -U $POSTGRES_USER -c "
    SELECT bdr.bdr_group_create(
      local_node_name := '${HOSTNAME}',
      node_external_dsn := 'host=${HOSTNAME}.${host} ${connectionString}'
    );"


else

  log "The cluster already exists, joining server group..."

  psql -U $POSTGRES_USER -c "
    SELECT bdr.bdr_group_join(
      local_node_name := '${HOSTNAME}',
      node_external_dsn := 'host=${HOSTNAME}.${host} ${connectionString}',
      join_using_dsn := 'host=${pod}.${host} ${connectionString}'
    );"

fi

log "Configuration done !"
