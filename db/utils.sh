wait_for_mysql() {
  set +e
  if [ $# -ne 2 ]; then
    echo "usage: wait_for_mysql <port> <root_pwd>" 1>&2
    return 1
  fi
  port="$1"
  root_pwd="$2"
  failure=1
  tries=30
  while [ "$failure" -ne 0 ]; do
    tries=`expr "$tries" - 1`
    if [ "$tries" -eq 0 ]; then
      echo "Could not connect to mysql server" 1>&2
      return 1
    fi
    sleep 1
    echo 'select 1;' | mysql -P$port "-h127.0.0.1" -uroot "-p$root_pwd" 2>/dev/null
    failure=$?
  done
  return 0
}
