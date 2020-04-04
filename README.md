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
name: gui

templates:
  bin/ctl.sh.erb: bin/ctl

packages:
  - ruby-2.6.5-r0.29.0
  - gui

properties:
  lexer:
    host:
      description: "The hostname or IP address which the lexer app is running."
      default: localhost
    port:
      description: "The port number which the ruby lexer app is listening."
      default: 3000
  gui:
    host:
      description: "The hostname or IP address which the GUI app is running."
      default: localhost
    port:
      description: "The port number which the ruby GUI app is listening."
      default: 2000
  calculator:
    host:
      description: "The hostname or IP address which the calculator app is running."
      default: localhost
    port:
      description: "The port number which the ruby calculator app is listening."
      default: 4000
 nginx:
    host:
      description: "The hostname or IP address which the NGINX app is running."
      default: localhost
    port:
      description: "The port number which the ruby NGINX app is listening."
      default: 8080
```

### Add the ctl.sh.erb script to templates/bin

```yaml
jobs
├── gui
│   ├── monit
│   ├── spec
│   └── templates
│       └── bin
│           └── ctl.sh.erb
```

### The content of the `ctl.sh.erb` file

```yaml
#!/bin/bash

RUN_DIR=/var/vcap/sys/run/gui
LOG_DIR=/var/vcap/sys/log/gui
PIDFILE=${RUN_DIR}/pid


# Lexer app specific
export LEXER_HOST=<%= p('lexer.host') %>
export LEXER_PORT=<%= p('lexer.port') %>
export GUI_HOST=<%= p('gui.host') %>
export GUI_PORT=<%= p('gui.port') %>
export CALCULATOR_HOST=<%= p('calculator.host') %>
export CALCULATOR_PORT=<%= p('calculator.port') %>
export NGINX_HOST=<%= p('nginx.host') %>
export NGINX_PORT=<%= p('nginx.port') %>


case $1 in

  start)
    mkdir -p $RUN_DIR $LOG_DIR
    chown -R vcap:vcap $RUN_DIR $LOG_DIR

    echo $$ > $PIDFILE

    cd /var/vcap/packages/gui

    export PATH=/var/vcap/packages/ruby-2.6.5-r0.29.0/bin:$PATH

    exec /var/vcap/packages/ruby-2.6.5-r0.29.0/bin/bundle exec \
      rackup --host ${gui_HOST} \
             --port ${gui_PORT} \
      >>  $LOG_DIR/gui.stdout.log \
      2>> $LOG_DIR/gui.stderr.log

    ;;

  stop)
    kill -9 `cat $PIDFILE`
    rm -f $PIDFILE

    ;;

  *)
    echo "Usage: ctl {start|stop}" ;;

esac

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

cp -a gui/* ${BOSH_INSTALL_TARGET}

cd ${BOSH_INSTALL_TARGET}

source /var/vcap/packages/ruby-2.6.5-r0.29.0/bosh/compile.env
bundle_cmd=/var/vcap/packages/ruby-2.6.5-r0.29.0/bin/bundle

# ${bundle_cmd} config set deployment 'true'
# ${bundle_cmd} config set local 'true'
# ${bundle_cmd} install

${bundle_cmd} install --local --deployment --without development test
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

### Overview of the folder structure

```yaml
.
└── gui-boshrelease
    ├── config
    │   ├── blobs.yml
    │   ├── final.yml
    │   └── private.yml
    ├── jobs
    │   └── gui
    │       ├── monit
    │       ├── spec
    │       └── templates
    │           └── bin
    │               └── ctl.sh.erb
    ├── packages
    │   ├── gui
    │   │   ├── packaging
    │   │   └── spec
    │   └── ruby-2.6.5-r0.29.0
    │       └── spec.lock
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
gui-boshrelease
├── config
│   ├── blobs.yml
│   ├── final.yml
│   └── private.yml
├── jobs
│   └── gui
│       ├── monit
│       ├── spec
│       └── templates
│           └── bin
│               └── ctl.sh.erb
├── packages
│   ├── gui
│   │   ├── packaging
│   │   └── spec
│   └── ruby-2.6.5-r0.29.0
│       └── spec.lock
└── src
    └── gui
        ├── Gemfile
        ├── Gemfile.lock
        ├── app.rb
        ├── config.ru
        ├── lib
        │   ├── gui.rb
        │   ├── rpn_calculator.rb
        │   └── token.rb
        └── vendor
            └── cache
                ├── json-2.3.0.gem
                ├── mustermann-1.1.1.gem
                ├── rack-2.2.2.gem
                ├── rack-protection-2.0.8.1.gem
                ├── ruby2_keywords-0.0.2.gem
                ├── sinatra-2.0.8.1.gem
                └── tilt-2.0.10.gem

13 directories, 23 files
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
```
