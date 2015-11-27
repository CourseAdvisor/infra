#!/bin/sh

usage() {
  cat 1>&2 <<EOF
  usage: frontend.sh (command [args] | help)

Available commands:
  slave : Replication slave
  help : Prints this help message

For command-specific usage instructions, run frontend.sh command --help
EOF
}


if [ $# -lt 2 ]; then
  usage
  exit 1
fi

if [ ! -e `pwd`/env ]; then
  echo "Please provide the environment variables file './env'" 1>&2
  exit 1
fi

. `pwd`/env

prog="$1"
shift

case "$prog" in
  help|--help|-h)
    usage
    exit 0
  ;;
  slave)
    cd db/slave
    ./slave.sh $@
  ;;
  *)
    usage
  ;;
esac
