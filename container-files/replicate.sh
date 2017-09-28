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

echo "APP_NAME : $APP_NAME"
if [[ "$APP_NAME" != "" ]]; then

  oc config set-cluster http://kubernetes.default
  echo "OC GET POD : $(oc get pod --selector=app=$APP_NAME)"
  pod=$(oc get pod --selector=app=$APP_NAME --no-headers | awk '{print $1;exit}')
  namespace=$(oc get namespace $APP_NAME --no-headers | awk '{print $1;exit}')
  service=$(oc get svc --selector=app=$APP_NAME --no-headers | awk '{print $1;exit}')

  if [ "$pod" ]; then
    #rejoindre cluster
    echo
  elif [ -z "$pod" ]; then

    psql $POSTGRES_DB -U $POSTGRES_USER -c "
      CREATE EXTENSION IF NOT EXISTS btree_gist;
      CREATE EXTENSION IF NOT EXISTS bdr;"

    psql $POSTGRES_DB -U $POSTGRES_USER -c "
      SELECT bdr.bdr_group_create(
        local_node_name := '${pod}',
        node_external_dsn := 'host=${pod}.${service}.${namespace}.svc.cluster.local port=5432 dbname=${POSTGRES_DB}'
      );"

    psql $POSTGRES_DB -U $POSTGRES_USER -c "SELECT bdr.bdr_node_join_wait_for_ready();"
  fi
fi

#  message
#  log "Database started in ${MODE} mode"
#elif [ $MODE == 'slave' ]; then
#  sleep 15
#  log "User Selected replication method: ${MODE}"
#  while true; do if cat /var/lib/postgresql/data/pg_log/postgresql*.log | grep "database system is ready to accept connections"; then break; else sleep 1; fi done
#  psql $POSTGRES_DB -U $POSTGRES_USER -p $POSTGRES_PORT -c "CREATE EXTENSION IF NOT EXISTS btree_gist;"
#  psql $POSTGRES_DB -U $POSTGRES_USER -p $POSTGRES_PORT -c "CREATE EXTENSION IF NOT EXISTS bdr;"
#  psql $POSTGRES_DB -U $POSTGRES_USER -p $POSTGRES_PORT -c "SELECT bdr.bdr_group_join(
#    local_node_name := '${HOSTNAME}',
#    node_external_dsn := 'host=${HOSTNAME} port=${SLAVE_PORT} dbname=${POSTGRES_DB} user=${POSTGRES_USER} password=${POSTGRES_PASSWORD}',
#    join_using_dsn := 'host=${MASTER_ADDRESS} port=${MASTER_PORT} dbname=${POSTGRES_DB} user=${POSTGRES_USER} password=${POSTGRES_PASSWORD}'
#  );"
#  psql $POSTGRES_DB -U $POSTGRES_USER -p $POSTGRES_PORT -c "SELECT bdr.bdr_node_join_wait_for_ready();"
#  message
#  log "Database started in ${MODE} mode"
#elif [ $MODE == 'single' ]; then
#  message
#  log "Database started in single mode. No replication!!!"
#fi
