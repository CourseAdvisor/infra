#!/bin/sh -e

. ../utils.sh

check_env() {
  if [ -z "$MASTER_ROOT_PASSWORD" ] || [ -z "$MASTER_DB_PASSWORD" ]; then
    echo "An environment variable is missing. Run --help for usage info." 1>&2
    return 1
  fi
  if [ -z "$MASTER_EXPORTED_PORT" ]; then
    export MASTER_EXPORTED_PORT=3306
  fi
  if [ -z "$MASTER_DB_CONTAINER_NAME" ]; then
    export MASTER_DB_CONTAINER_NAME="courseadvisor-master"
  fi
}

setup() {
  # Create mysql docker image
  docker run --name "$MASTER_DB_CONTAINER_NAME" -p $MASTER_EXPORTED_PORT:3306 -e "MYSQL_ROOT_PASSWORD=$MASTER_ROOT_PASSWORD" \
    -e MYSQL_DATABASE=master -e MYSQL_USER=master -e "MYSQL_PASSWORD=$MASTER_DB_PASSWORD" -v `pwd`/conf:/etc/mysql/conf.d -d mysql:5.5
  echo "Waiting for mysql deamon to start"
  wait_for_mysql $MASTER_EXPORTED_PORT "$MASTER_ROOT_PASSWORD" 1>/dev/null
  # Creating slave user
  mysql -P$MASTER_EXPORTED_PORT -uroot "-p$MASTER_ROOT_PASSWORD" "-h127.0.0.1" <<EOF
GRANT RELOAD, REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO '$SLAVE_REPLICATION_USER'@'%' IDENTIFIED BY '$SLAVE_REPLICATION_PASSWORD';
GRANT SELECT, LOCK TABLES, SHOW VIEW ON \`master\`.* TO '$SLAVE_REPLICATION_USER'@'%';
EOF
  echo "Master database is running"
}

stop() {
  docker stop "$MASTER_DB_CONTAINER_NAME"
}

remove() {
  stop
  docker rm "$MASTER_DB_CONTAINER_NAME"
}

start() {
  docker start "$MASTER_DB_CONTAINER_NAME"
}

usage() {
  cat 1>&2 <<EOF
  usage: master (setup [-b <sqlfile>]|remove)

Sets up or removes the master db container. Sensible arguments are passed via env variables:

mandatory:
MASTER_DB_PASSWORD          : Password for master user
MASTER_ROOT_PASSWORD        : Password for root user

optionnal:
MASTER_EXPORTED_PORT : Which host port to bind to master's SQL (default 3306)
MASTER_DB_CONTAINER_NAME: Docker container name for the master (default courseadvisor-master)

options:
-b <sqlfile> : executes the sql statements in sqlfile using master database
EOF
}

check_env

case "$1" in
  "setup")
     setup
     shift
     if [ "$#" -ge 2 ] && [ "$1" = "-b" ]; then
       echo "Seeding database with $2"
       echo "use master;" | cat - "$2" | mysql -P$MASTER_EXPORTED_PORT -umaster "-p$MASTER_DB_PASSWORD" "-h127.0.0.1"
     fi
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
