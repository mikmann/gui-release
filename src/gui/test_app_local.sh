#!/bin/bash

# Export the environment variables
export GUI_HOST=localhost
export GUI_PORT=4567

bundle exec rackup --host ${GUI_HOST} \
                   --port ${GUI_PORT}
