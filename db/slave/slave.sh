#!/bin/sh -e
# server-id   = 2
# relay-log   = /var/log/mysql/mysql-relay-bin.log
# log_bin     = /var/log/mysql/mysql-bin.log
# replicate-do-db   = courseadvisor
# report-host = hmil.fr
#
# position: 107

check_env() {
  if [ -z "$SLAVE_ROOT_PASSWORD" ] || [ -z "$SLAVE_REPLICATION_PASSWORD" ] || [ -z "$SLAVE_REPLICATION_USER" ]; then
    echo "An environment variable is missing. Run --help for usage info." 1>&2
    return 1
  fi
  if [ -z "$SLAVE_EXPORTED_PORT" ]; then
    export SLAVE_EXPORTED_PORT=3300
  fi
  if [ -z "$SLAVE_CONTAINER_NAME" ]; then
    export SLAVE_CONTAINER_NAME="courseadvisor-slave"
  fi
}

wait_for_mysql() {
  set +e
  failure=1
  tries=30
  while [ "$failure" -ne 0 ]; do
    tries=`expr $tries - 1`
    if [ $tries -eq 0 ]; then
      echo "Could not connect to mysql server" 1>&2
      return 1
    fi
    sleep 1
    echo 'select 1;' | mysql -P$SLAVE_EXPORTED_PORT -h"127.0.0.1" -uroot -p$SLAVE_ROOT_PASSWORD 2>/dev/null
    failure=$?
  done
  return 0
}

setup() {
  # prepare configuration with random slave number
  server_id=`tr -cd 0-9 </dev/urandom | head -c 6`
  server_name=`hostname`
  cat slave_config.cnf | sed "s/__SERVER_ID__/$server_id/" | sed "s/__SERVER_NAME__/$server_name/" > conf/slave_config.cnf
  # Create mysql docker image
  docker run --name ${SLAVE_CONTAINER_NAME} -p ${SLAVE_EXPORTED_PORT}:3306 -e MYSQL_ROOT_PASSWORD=${SLAVE_ROOT_PASSWORD} -e MYSQL_DATABASE=master -v `pwd`/conf:/etc/mysql/conf.d -d mysql:5.5
  echo "Waiting for mysql deamon to start"
  wait_for_mysql 1>/dev/null
  echo "Dumping master state (warning: locks master DB)"
  # Seeds database with snapshot data, replication log position is set to take over right after this snapshot
  mysqldump -P5467 -u${SLAVE_REPLICATION_USER} -h"courseadvisor.ch" -p${SLAVE_REPLICATION_PASSWORD} --master-data -B master |
    sed "s/CHANGE MASTER TO/CHANGE MASTER TO MASTER_HOST='courseadvisor.ch',MASTER_PORT=5467,MASTER_USER='${SLAVE_REPLICATION_USER}',MASTER_PASSWORD='${SLAVE_REPLICATION_PASSWORD}',/" |
    mysql -P${SLAVE_EXPORTED_PORT} -h"127.0.0.1" -uroot -p${SLAVE_ROOT_PASSWORD}

  echo "Starting slave replication"
  # Sets up remote master
  echo "START SLAVE;" | mysql -P${SLAVE_EXPORTED_PORT} -h"127.0.0.1" -uroot -p${SLAVE_ROOT_PASSWORD}
  echo "Slave instance is running"
}

stop() {
  docker stop $SLAVE_CONTAINER_NAME
}

remove() {
  stop
  docker rm $SLAVE_CONTAINER_NAME
}

start() {
  docker start $SLAVE_CONTAINER_NAME
}

usage() {
  cat 1>&2 <<EOF
  usage: slave (setup|remove)

Sets up or removes the slave docker image. Sensible arguments are passed via env variables:

mandatory:
SLAVE_REPLICATION_USER     : Replication user on master host
SLAVE_REPLICATION_PASSWORD : Replication user password on master host
SLAVE_ROOT_PASSWORD        : Password for root user on local slave instance

optionnal:
SLAVE_EXPORTED_PORT : Which host port to bind to slave's SQL (default 3300)
SLAVE_CONTAINER_NAME: Docker container name for the slave (default courseadvisor-slave)
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
