#!/bin/bash

# Export the environment variables
export GUI_HOST=localhost
export GUI_PORT=5000

export ENV=test
bundle config set without 'development'

bundle exec rspec spec
