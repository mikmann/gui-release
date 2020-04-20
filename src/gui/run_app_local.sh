#!/bin/bash

# Export the environment variables
export GUI_HOST=localhost
export GUI_PORT=5000

export ENV=development
bundle config --local with 'development'
bundle config --local without 'test'
bundle install

shotgun app.rb --host ${GUI_HOST} --port ${GUI_PORT}

rm -rf .bundle
