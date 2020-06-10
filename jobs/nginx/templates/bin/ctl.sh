#!/bin/bash

set -e # exit immediately if a simple command exits with a non-zero status
set -u # report the usage of uninitialized variables

job_name=nginx

export run_dir=/var/vcap/sys/run/${job_name}
export log_dir=/var/vcap/sys/log/${job_name}
export tmp_dir=/var/vcap/sys/tmp/${job_name}
export store_dir=/var/vcap/store/${job_name}
export config_dir=/var/vcap/jobs/${job_name}/config
export pid_file=${run_dir}/${job_name}.pid
export packages_dir=/var/vcap/packages


for dir in ${run_dir} ${log_dir} ${tmp_dir} ${store_dir} ; do
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
    cd ${packages_dir}
    nginx_version=$(find nginx-*)

    if [[ $? != 0 ]]
    then
      echo "No NGINX Version found"
      exit 1
    fi

    source ${packages_dir}/${nginx_version}/bosh/runtime.env

    nginx -g "pid ${pid_file};" -c ${config_dir}/nginx.conf
    ;;

  stop)
    timeout="25"

    if [ ! -f "${pid_file}" ]; then
      echo "Pidfile ${pid_file} doesn't exist"
      exit 0
    fi
    pid=$(head -1 ${pid_file})

    if [ -z "${pid}" ]; then
      echo "Unable to get pid from ${pid_file}"
      exit 1
    fi

    if [ $(ps -p "${pid}" | wc -l) -le 1 ]; then
      echo "Process ${pid} is not running"
      rm -f "${pid_file}"
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
      rm -f "${pid_file}"
    fi

    ;;
  *)
    echo "Usage: ctl {start|stop}" ;;

esac
