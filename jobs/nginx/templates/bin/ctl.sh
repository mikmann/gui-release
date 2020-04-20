#!/bin/bash

set -e # exit immediately if a simple command exits with a non-zero status
set -u # report the usage of uninitialized variables

JOB_NAME="nginx"

export RUN_DIR=/var/vcap/sys/run/$JOB_NAME
export LOG_DIR=/var/vcap/sys/log/$JOB_NAME
export TMP_DIR=/var/vcap/sys/tmp/$JOB_NAME
export STORE_DIR=/var/vcap/store/$JOB_NAME
export JOB_DIR=/var/vcap/jobs/$JOB_NAME

export CONF_DIR=/var/vcap/jobs/$JOB_NAME/config

export PIDFILE=$RUN_DIR/$JOB_NAME.pid

source /var/vcap/packages/nginx-1.17.3/bosh/runtime.env

for dir in $RUN_DIR $LOG_DIR $TMP_DIR $STORE_DIR ; do
  if ! [ -d $dir ] ; then
    mkdir -p $dir
  fi
  chown -R vcap:vcap $dir
  chmod 775 $dir
done

function wait_pid_death() {
  declare pid="$1" timeout="$2"

  local countdown
  countdown=$(( timeout * 10 ))

  while true; do
    # If Process is not running anymore everything worked
    if [ $(ps -p "${pid}" | wc -l) -le 1 ] ; then
      return 0
    fi

    # If Countdown is on zero, the process could not be stopped normally
    if [ ${countdown} -le 0 ]; then
      return 1
    fi

    countdown=$(( countdown - 1 ))
    sleep 0.1
  done
}

case $1 in

  start)

    nginx -g "pid $PIDFILE;" -c $CONF_DIR/nginx.conf
    ;;
  stop)
    timeout="25"

    if [ ! -f "${PIDFILE}" ]; then
      echo "Pidfile ${PIDFILE} doesn't exist"
      exit 0
    fi
    pid=$(head -1 $PIDFILE)

    if [ -z "${pid}" ]; then
      echo "Unable to get pid from ${PIDFILE}"
      exit 1
    fi

    if [ $(ps -p "${pid}" | wc -l) -le 1 ]; then
      echo "Process ${pid} is not running"
      rm -f "${PIDFILE}"
      exit 0
    fi

    kill ${pid}

    # If Process is not stopped within timeout, use kill -9
    if ! wait_pid_death "${pid}" "${timeout}"; then
        echo "Kill timed out, using kill -9 on ${pid}"
        kill -9 "${pid}"
        sleep 0.5
    fi

    # If Process is still running
    if [ $(ps -p "${pid}" | wc -l) -gt 1 ] ; then
      echo "Timed Out"
      exit 1
    else
      echo "Stopped"
      rm -f "${PIDFILE}"
    fi

    ;;
  *)
    echo "Usage: ctl {start|stop}"
    ;;
esac
