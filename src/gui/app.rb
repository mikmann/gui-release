# frozen_string_literal: true

require 'rubygems'
require 'bundler'
require 'sinatra'
require 'json'
require 'Date'
require_relative 'lib/http_rest_adapter'

# Set environment variables
LEXER_HOST = ENV['LEXER_HOST'] || 'localhost'
LEXER_PORT = ENV['LEXER_PORT'] || '3000'
GUI_HOST = ENV['GUI_HOST'] || 'localhost'
GUI_PORT = ENV['GUI_PORT'] || '5000'
CALCULATOR_HOST = ENV['CALCULATOR_HOST'] || 'localhost'
CALCULATOR_PORT = ENV['CALCULATOR_PORT'] || '4000'
NGINX_HOST = ENV['NGINX_HOST']
NGINX_PORT = ENV['NGINX_PORT']
DB_HOST = ENV['DB_HOST'] || 'localhost'
DB_PORT = ENV['DB_PORT'] || '6000'

helpers do
  def config
    {
      gui: "http://#{GUI_HOST}:#{GUI_PORT}",
      remote_services: {
        lexer: "http://#{LEXER_HOST}:#{LEXER_PORT}",
        calculator: "http://#{CALCULATOR_HOST}:#{CALCULATOR_PORT}",
        database: "http://#{DB_HOST}:#{DB_PORT}"
      },
      service_colors: {
        lexer: 'info',
        calculator: 'danger',
        database: 'warning'
      }
    }
  end

  def check_which_remote_service_is_alive
    remote_services = config[:remote_services]
    response_services = []

    remote_services.each do |name, url|
      begin
        HTTPRestAdapter.new(url).http_get('/is_alive')
        response_services << { service: name, alive: true }
      rescue Errno::ECONNREFUSED => _e
        # TODO: log the result
        response_services << { service: name, alive: false }
      end
    end

    response_services
  end
end

before do
  content_type 'application/json'
end

get '/' do
  content_type 'html'
  erb :user_input, locals: config, layout: :layout
end

get '/is_alive' do
  check_which_remote_service_is_alive.to_json
end

post '/lexer' do
  expression = params[:expression]
  puts expression
  rpn = HTTPRestAdapter.new("http://#{LEXER_HOST}:#{LEXER_PORT}").http_get('lexer', expression)
  rpn.to_json
end

post '/calculator' do
  rpn = params[:rpn]
  result = HTTPRestAdapter.new("http://#{CALCULATOR_HOST}:#{CALCULATOR_PORT}").http_get('calculator', rpn)
  result.to_json
end

# Database endpoints
post '/database/tasks' do
  task = params[:task]
  result = HTTPRestAdapter.new("http://#{DB_HOST}:#{DB_PORT}").http_post('tasks', task)
  result.to_json
end

get '/database/tasks' do
  result = HTTPRestAdapter.new("http://#{DB_HOST}:#{DB_PORT}").http_get('tasks')
  result.to_json
end

put '/database/tasks/:id' do
  id = params[:id]
  result = HTTPRestAdapter.new("http://#{DB_HOST}:#{DB_PORT}").http_get('tasks/', id)
  result.to_json
end

delete '/database/tasks/:id' do
  id = params[:id]
  result = HTTPRestAdapter.new("http://#{DB_HOST}:#{DB_PORT}").http_delete("tasks/#{id}")
  result.to_json
end
