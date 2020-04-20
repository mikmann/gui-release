#!/bin/bash

# Export the environment variables
export GUI_HOST=localhost
export GUI_PORT=5000

export ENV=test
bundle config --local set with 'test'
bundle config --local set without 'development'
bundle install

bundle exec rspec spec --format documentation

rm -rf .bundle
