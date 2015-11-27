#!/bin/sh -e

. ../utils.sh

check_env() {
  if [ -z "$SLAVE_ROOT_PASSWORD" ] || [ -z "$SLAVE_REPLICATION_PASSWORD" ] || [ -z "$SLAVE_REPLICATION_USER" ] \
    || [ -z "$MASTER_HOST" ]; then
    echo "An environment variable is missing. Run --help for usage info." 1>&2
    return 1
  fi
  if [ -z "$SLAVE_EXPORTED_PORT" ]; then
    export SLAVE_EXPORTED_PORT=3300
  fi
  if [ -z "$SLAVE_DB_CONTAINER_NAME" ]; then
    export SLAVE_DB_CONTAINER_NAME="courseadvisor-slave"
  fi
}

setup() {
  # prepare configuration with random slave number
  server_id=`tr -cd 0-9 </dev/urandom | head -c 6`
  server_name=`hostname`
  cat slave_config.cnf | sed "s/__SERVER_ID__/$server_id/" | sed "s/__SERVER_NAME__/$server_name/" > conf/slave_config.cnf
  # Create mysql docker image
  docker run --name "$SLAVE_DB_CONTAINER_NAME" -p $SLAVE_EXPORTED_PORT:3306 -e MYSQL_ROOT_PASSWORD="$SLAVE_ROOT_PASSWORD" -e MYSQL_DATABASE=master -v `pwd`/conf:/etc/mysql/conf.d -d mysql:5.5
  echo "Waiting for mysql deamon to start"
  wait_for_mysql $SLAVE_EXPORTED_PORT "$SLAVE_ROOT_PASSWORD" 1>/dev/null
  echo "Dumping master state (warning: locks master DB)"
  # Seeds database with snapshot data, replication log position is set to take over right after this snapshot
  mysqldump -P$MASTER_EXPORTED_PORT "-u$SLAVE_REPLICATION_USER" "-h$MASTER_HOST" "-p$SLAVE_REPLICATION_PASSWORD" --master-data -B master |
    sed "s/CHANGE MASTER TO /CHANGE MASTER TO MASTER_HOST='$MASTER_HOST',MASTER_PORT=$MASTER_EXPORTED_PORT,MASTER_USER='$SLAVE_REPLICATION_USER',MASTER_PASSWORD='$SLAVE_REPLICATION_PASSWORD',/" |
    mysql -P$SLAVE_EXPORTED_PORT -h"127.0.0.1" -uroot "-p$SLAVE_ROOT_PASSWORD"

  echo "Starting slave replication"
  # Sets up remote master
  echo "START SLAVE;" | mysql -P$SLAVE_EXPORTED_PORT "-h127.0.0.1" -uroot "-p$SLAVE_ROOT_PASSWORD"
  echo "Slave instance is running"
}

stop() {
  docker stop "$SLAVE_DB_CONTAINER_NAME"
}

remove() {
  stop
  docker rm "$SLAVE_DB_CONTAINER_NAME"
}

start() {
  docker start "$SLAVE_DB_CONTAINER_NAME"
}

usage() {
  cat 1>&2 <<EOF
  usage: slave (setup|remove)

Sets up or removes the slave docker image. Sensible arguments are passed via env variables:

mandatory:
SLAVE_REPLICATION_USER     : Replication user on master host
SLAVE_REPLICATION_PASSWORD : Replication user password on master host
SLAVE_ROOT_PASSWORD        : Password for root user on local slave instance
MASTER_HOST                : Host of the master server

optionnal:
SLAVE_EXPORTED_PORT : Which host port to bind to slave's SQL (default 3300)
SLAVE_DB_CONTAINER_NAME: Docker container name for the slave (default courseadvisor-slave)
EOF
}

check_env

case "$1" in
  "setup")
     setup
  ;;
  "remove")
    remove
  ;;
  "stop")
    stop
  ;;
  "start")
    start
  ;;
  *)
    usage
  ;;
esac
