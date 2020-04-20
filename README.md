# Sinatra App GUI

## Initialize the Boshrelease with gitignore file

```yaml
$ bosh init-release --git --dir gui-boshrelease

gui-boshrelease
├── config
│   ├── blobs.yml
│   └── final.yml
├── jobs
├── packages
└── src

4 directories, 2 files
```

### Add the private.yml to the config folder

```yaml
---
blobstore:
  options:
    access_key_id: XXXXXXXXXXXXX
    secret_access_key: XXXXXXXXXXXXX
```

### Change the content of the final.yml approximately to

```yaml
---
final_name: gui-boshrelease
blobstore:
  provider: s3
  options:
    bucket_name: xxx
    endpoint: https://s3-eu-west-1.amazonaws.com
    region: eu-west-1
```


## Create gui job

### Generate the folder structure

```yaml
$ bosh generate-job gui

jobs
└── gui
    ├── monit
    ├── spec
    └── templates
```

### Add the monit script

```yaml
check process gui
  with pidfile /var/vcap/sys/run/gui/pid
  start program "/var/vcap/jobs/gui/bin/ctl start"
  stop program "/var/vcap/jobs/gui/bin/ctl stop"
  group vcap
```

### Add content of the spec

```yaml
---
---
name: gui

templates:
  bin/ctl.sh.erb: bin/ctl

provides:
- name: nodes
  type: http

packages:
  - ruby-2.6.5-r0.29.0
  - gui

properties:
  gui:
    host:
      description: "The hostname or IP address which the GUI app is running."
      default: localhost
    port:
      description: "The port number which the ruby GUI app is listening."
      default: 5000
  lexer:
    port:
      description: "The port number which the ruby lexer app is listening."
      default: 3000
  calculator:
    port:
      description: "The port number which the ruby calculator app is listening."
      default: 4000
  database:
    port:
      description: "The port number which the ruby database app is listening."
      default: 6000
  nginx:
    host:
      description: "The hostname or IP address which the NGINX app is running."
      default: localhost
    port:
      description: "The port number which the ruby NGINX app is listening."
      default: 8080
  consul:
    dc:
      description: "Consul DC"
      default: dc1
    domain:
      description: "Consul Domain"
      default: consul.dsf2
```

### Add the ctl.sh.erb script to templates/bin

```yaml
jobs
├── gui
│   ├── monit
│   ├── spec
│   └── templates
│       └── bin
│           └── ctl.sh.erb
```

### The content of the `ctl.sh.erb` file

```yaml
#!/bin/bash

job_name=gui
run_dir=/var/vcap/sys/run/${job_name}
log_dir=/var/vcap/sys/log/${job_name}
pid_file=${run_dir}/pid
packages_dir=/var/vcap/packages

# Set environment variables
export GUI_HOST=<%= p('gui.host') %>
export GUI_PORT=<%= p('gui.port') %>
export LEXER_PORT=<%= p('lexer.port') %>
export CALCULATOR_PORT=<%= p('calculator.port') %>
export DB_PORT=<%= p('database.port') %>
export NODE_ROUTE=<%= "#{spec.deployment}-#{spec.deployment}-0.node.#{p('consul.dc')}.#{p('consul.domain')}" %>

case $1 in

  start)
    cd ${packages_dir}
    ruby_version=$(find ruby-*)

    if [[ $? != 0 ]]
    then
      echo "No Ruby Version found"
      exit 1
    fi

    source ${packages_dir}/${ruby_version}/bosh/runtime.env

    mkdir -p ${run_dir} ${log_dir}
    chown -R vcap:vcap ${run_dir} ${log_dir}

    echo $$ > ${pid_file}

    cd ${packages_dir}/${job_name}

    exec bundle exec \
      rackup --host ${GUI_HOST} \
             --port ${GUI_PORT} \
      >>  ${log_dir}/${job_name}.stdout.log \
      2>> ${log_dir}/${job_name}.stderr.log

    ;;

  stop)
    kill -9 `cat ${pid_file}`
    rm -f ${pid_file}

    pid=$(ps aux | grep ${job_name}/gem_home/ | cut -d " " -f6 | head -n 1)
    kill -9 ${pid}

    ;;

  *)
    echo "Usage: ctl {start|stop}" ;;

esac
```



## Create nginx job

### Generate the folder structure

```yaml
nginx
├── monit
├── spec
└── templates
    ├── bin
    │   └── ctl.sh
    ├── config
    │   ├── nginx.conf
    │   └── upstream.conf
    └── nginx-error-pages
        ├── 404.html
        └── 50x.html

4 directories, 7 files
```

### Add the monit script

```yaml
check process nginx
	with pidfile /var/vcap/sys/run/nginx/nginx.pid
	start program "/var/vcap/jobs/nginx/bin/ctl start"
	stop program "/var/vcap/jobs/nginx/bin/ctl stop"
	group vcap
```

### Add content of the spec

```yaml
---
name: nginx

templates:
  bin/ctl.sh: bin/ctl
  config/nginx.conf: config/nginx.conf
  config/upstream.conf: config/upstream.conf
  nginx-error-pages/404.html: nginx-error-pages/404.html
  nginx-error-pages/50x.html: nginx-error-pages/50x.html

packages:
- nginx-1.17.3

properties:
  nginx:
    upstream_host:
      description: 'Upstream host'
      default: 127.0.0.1
    upstream_port:
      description: 'Upstream port'
      default: 80
  gui:
    port:
      description: "The port number which the ruby GUI app is listening."
      default: 5000
  consul:
    dc:
      description: "This defines the datacenter in which the agent is running."
      default: dc1
    domain:
      description: "This defines the domain in which the agent is running."
      default: consul.dsf2
```


### The content of the `ctl.sh.erb` file

```yaml#!/bin/bash

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
```

### Create the nginx.conf file

```yaml

user  vcap;
worker_processes  12;
worker_rlimit_nofile 4096;

error_log  /var/vcap/sys/log/nginx/error.log   notice;

events {
    worker_connections  2048;
    use epoll;
}

http {
    include       /var/vcap/packages/nginx-1.17.3/conf/mime.types;
    default_type  application/octet-stream;

    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/vcap/sys/log/nginx/access.log  main;

    map $http_upgrade $connection_upgrade {
        default upgrade;
        ''      close;
    }

    client_max_body_size 32M;

    sendfile         on;
    tcp_nopush      on;
    tcp_nodelay     on;

    keepalive_timeout  75 20;

    include /var/vcap/jobs/nginx/config/upstream.conf;

    proxy_read_timeout 300;
    proxy_send_timeout 300;
    proxy_headers_hash_bucket_size 128;

}
```

### Create the upstream.conf file

```yaml
upstream sso-upstream {
    server <%= "#{spec.deployment}-#{spec.deployment}-0.node.#{p('consul.dc')}.#{p('consul.domain')}" %>:<%= p('gui.port') %>;
}

server {
    listen <%= p('nginx.upstream_host') %>:<%= p('nginx.upstream_port') %>;

    access_log  /var/vcap/sys/log/nginx/upstream.access.log  main;
    error_log   /var/vcap/sys/log/nginx/upstream.error.log;

    location / {
        proxy_buffering  off;
        proxy_redirect off;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Server $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Host $http_host;

        proxy_pass http://sso-upstream;
        proxy_intercept_errors on;
    }

    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
      root   /var/vcap/jobs/nginx/nginx-error-pages;
    }

    error_page   404 /404.html;
    location = /404.html {
      root   /var/vcap/jobs/nginx/nginx-error-pages;
    }

    location ~ /\.ht {
      deny  all;
    }
}
```

## Generate the packages

### Generate ruby-2.6.5-r0.29.0 package

```yaml
$ bosh generate-package ruby-2.6.5-r0.29.0

packages
└── ruby-2.6.5-r0.29.0
    ├── packaging
    └── spec
```

Add the vendor ruby package to the release

```yaml
git clone https://github.com/bosh-packages/ruby-release
cd ~/workspace/your-release
bosh vendor-package <RUBY-PACKAGE-VERSION> ~/workspace/ruby-release

git clone https://github.com/bosh-packages/ruby-release
cd gui-boshrelease
bosh vendor-package ruby-2.6.5-r0.29.0 ../ruby-release
```

Where RUBY-PACKAGE-VERSION is one of the provided ruby 2.5 or 2.6 package names (e.g. ruby-2.6.5-r0.29.0 or ruby-2.5.7-r0.25.0).\
The above code will add a ruby package to your-release and introduce a spec.lock.

Included packages:

- ruby package with the following blobs:
  - ruby (2.5, or 2.6)
  - rubygems (2.7, or 3.1)
  - yaml (0.1)

For further information you can visit the link:
[https://github.com/bosh-packages/ruby-release#ruby-release](https://github.com/bosh-packages/ruby-release#ruby-release)

Result of the commando

```yaml
packages
└── ruby-2.6.5-r0.29.0
    └── spec.lock
```

### Generate gui package

```yaml
$ bosh generate-package gui

packages
└── gui
    ├── packaging
    └── spec
```

Fill the packaging file

```yaml
set -e -x

package_name=$(echo ${BOSH_INSTALL_TARGET} | cut -d "/" -f5)
packages_dir=$(echo ${BOSH_INSTALL_TARGET} | cut -d "/" -f1-4)

cp -a ${package_name}/* ${BOSH_INSTALL_TARGET}

cd ${packages_dir}
ruby_version=$(find ruby-*)

if [[ $? != 0 ]]
then
  echo "No Ruby Version found"
  exit 1
fi

source ${packages_dir}/${ruby_version}/bosh/compile.env

cd ${BOSH_INSTALL_TARGET}

bosh_bundle_local --gemfile="${BOSH_INSTALL_TARGET}/Gemfile"
bosh_generate_runtime_env
```

Fill the spec file

```yaml
---
name: gui

dependencies:
- ruby-2.6.5-r0.29.0

files:
- gui/**/*
```

### Generate nginx package

The same steps as for ruby package.

### Overview of the folder structure

```yaml
.
└── gui-boshrelease
    ├── config
    │   ├── blobs.yml
    │   ├── final.yml
    │   └── private.yml
    ├── jobs
    │   └── gui
    │       ├── monit
    │       ├── spec
    │       └── templates
    │           └── bin
    │               └── ctl.sh.erb
    ├── packages
    │   ├── gui
    │   │   ├── packaging
    │   │   └── spec
    │   └── ruby-2.6.5-r0.29.0
    │       └── spec.lock
    └── src
```

## Prepare the App and Vendors

### Copy all necessary files of the gui app into the Bosh Release

```yaml
# Copy the gui app to the src folder
$ cp -Ra ~/gui ~/gui-boshrelease/src
```

### Pack all necessary gems in the vendor folder

```yaml
# Pack all necessary gems in the vendor folder
cd src/gui/
bundle package
```



## The folder and files structure of the gui BOSH Release

```yaml
gui-release
├── README.md
├── config
│   ├── blobs.yml
│   └── final.yml
├── examples
│   ├── gui.yml
│   └── iaas
│       └── config.yml
├── jobs
│   ├── gui
│   │   ├── monit
│   │   ├── spec
│   │   └── templates
│   │       └── bin
│   │           └── ctl.sh.erb
│   └── nginx
│       ├── monit
│       ├── spec
│       └── templates
│           ├── bin
│           │   └── ctl.sh
│           ├── config
│           │   ├── nginx.conf
│           │   └── upstream.conf
│           └── nginx-error-pages
│               ├── 404.html
│               └── 50x.html
├── packages
│   ├── gui
│   │   ├── packaging
│   │   └── spec
│   ├── nginx-1.17.3
│   │   └── spec.lock
│   └── ruby-2.6.5-r0.29.0
│       └── spec.lock
└── src
    └── gui
        ├── Gemfile
        ├── Gemfile.lock
        ├── app.rb
        ├── config.ru
        ├── lib
        │   └── http_rest_adapter.rb
        ├── public
        │   ├── scripts
        │   │   ├── app.js
        │   │   ├── bootstrap.min.css
        │   │   ├── jquery.js
        │   │   ├── jquery.min.js
        │   │   ├── knockout.js
        │   │   └── modernizr.js
        │   └── styles
        │       └── styles.css
        ├── run_app_local.sh
        ├── spec
        │   ├── app_spec.rb
        │   ├── helpers.rb
        │   ├── lib
        │   │   └── http_rest_adapter_spec.rb
        │   └── spec_helper.rb
        ├── test_app_local.sh
        ├── vendor
        │   └── cache
        │       ├── addressable-2.7.0.gem
        │       ├── crack-0.4.3.gem
        │       ├── diff-lcs-1.3.gem
        │       ├── hashdiff-1.0.1.gem
        │       ├── httparty-0.18.0.gem
        │       ├── json-2.3.0.gem
        │       ├── mime-types-3.3.1.gem
        │       ├── mime-types-data-3.2020.0512.gem
        │       ├── multi_xml-0.6.0.gem
        │       ├── mustermann-1.1.1.gem
        │       ├── public_suffix-4.0.5.gem
        │       ├── rack-2.2.2.gem
        │       ├── rack-protection-2.0.8.1.gem
        │       ├── rspec-3.9.0.gem
        │       ├── rspec-core-3.9.2.gem
        │       ├── rspec-expectations-3.9.2.gem
        │       ├── rspec-mocks-3.9.1.gem
        │       ├── rspec-support-3.9.3.gem
        │       ├── ruby2_keywords-0.0.2.gem
        │       ├── safe_yaml-1.0.5.gem
        │       ├── shotgun-0.9.2.gem
        │       ├── sinatra-2.0.8.1.gem
        │       ├── tilt-2.0.10.gem
        │       └── webmock-3.8.3.gem
        └── views
            ├── layout.erb
            └── user_input.erb
```

## Here an example of a simple manifest

```yaml
---
name: gui-deployment

releases:
- name: gui
  version: latest

stemcells:
- alias: default
  os: ubuntu-xenial
  version: latest

update:
  canaries: 1
  max_in_flight: 1
  canary_watch_time: 1000-30000
  update_watch_time: 1000-30000

instance_groups:
- name: gui
  azs: [z1]
  instances: 1
  vm_type: nano
  stemcell: default
  networks:
  - name: dynamic

  jobs:
  - name: gui
    release: gui
    properties:
      lexer:
        host: localhost
        port: 5000
      gui:
        host: localhost
        port: 5000
      calculator:
        host: localhost
        port: 5000
      nginx:
        host: localhost
        port: 5000
```

## Here an example of an IaaS configuration for VSphere (Only necessary by deploy a consul)

```yaml
---
iaas:
  consul:
    dnsmasq_ips:
    - 172.28.35.20
    - 172.28.36.20
    - 172.28.37.20
    dnsmasq:
      upstream_nameservers:
      - 109.234.108.234
      - 109.234.109.234
    consul_ips:
    - 172.28.35.21
    - 172.28.36.21
    - 172.28.37.21
    join_ip: 172.28.35.21
    domain: consul.dsf2
```

## Deploy the GUI Bosh Release on VSphere

## Add RSpec test framework

```yaml
# Initialize the RSpec framework
$ rspec --init
  create   .rspec
  create   spec/spec_helper.rb

# Execute all test cases
$ rspec spec --format documentation
```


## TODOs

1. Separate Java Script script and CSS styles
2. Add test cases to the gui endpoints
3. Add test cases to the http_rest_adapter.rb class
4. Add a BASIC Authentication
