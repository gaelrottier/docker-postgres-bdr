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

log "Configuring PostgreSQL ${PG_MAJOR} BDR Cluster"

host="${APP_NAME}.${OC_NAMESPACE}.svc.cluster.local"
connectionString="port=5432 dbname=${POSTGRES_DB} user=${POSTGRES_USER} password=${POSTGRES_PASSWORD}"
pgnodeInfo="local_node_name := '${HOSTNAME}',
            node_external_dsn := 'host=${POD_IP} ${connectionString}'"

log "Creating extensions..."
"${psql[@]}" <<-EOSQL 
	CREATE EXTENSION IF NOT EXISTS btree_gist;
	CREATE EXTENSION IF NOT EXISTS bdr;
EOSQL

# First node created by StatefulSet creates the cluster
if [ "$HOSTNAME" == "$APP_NAME-0" ]; then

	log "First node in the cluster, creating server group..."

	"${psql[@]}" <<-EOSQL 
		SELECT bdr.bdr_group_create(
			${pgnodeInfo}
		);
	EOSQL


else

	log "The cluster already exists, joining server group..."

	pod=$(echo $HOSTNAME | awk -F "-" '{print $1"-"$2-1; exit;}')
	"${psql[@]}" <<-EOSQL 
		SELECT bdr.bdr_group_join(
			${pgnodeInfo},
			join_using_dsn := 'host=${pod}.${host} ${connectionString}'
		);
	EOSQL

fi

log "Configuration done !"
