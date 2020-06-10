# frozen_string_literal: true

require 'rubygems'
require 'bundler'
require 'sinatra'
require 'json'
require_relative 'lib/http_rest_adapter'

# Set environment variables
NODE_ROUTE = ENV['NODE_ROUTE']
GUI_HOST = ENV['GUI_HOST'] || 'localhost'
GUI_PORT = ENV['GUI_PORT'] || '5000'
LEXER_PORT = ENV['LEXER_PORT'] || '3000'
NODE_ROUTE_LEXER = ENV['NODE_ROUTE_LEXER'] || NODE_ROUTE
CALCULATOR_PORT = ENV['CALCULATOR_PORT'] || '4000'
NODE_ROUTE_CALCULATOR = ENV['NODE_ROUTE_CALCULATOR'] || NODE_ROUTE
DB_PORT = ENV['DB_PORT'] || '6000'
NODE_ROUTE_DB = ENV['NODE_ROUTE_DB'] || NODE_ROUTE

helpers do
  def config
    config ||= {
      remote_services: {
        lexer: "http://#{NODE_ROUTE_LEXER}:#{LEXER_PORT}",
        calculator: "http://#{NODE_ROUTE_CALCULATOR}:#{CALCULATOR_PORT}",
        database: "http://#{NODE_ROUTE_DB}:#{DB_PORT}"
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
  rpn = HTTPRestAdapter.new(config[:remote_services][:lexer]).http_get('lexer', expression)
  rpn.to_json
end

post '/calculator' do
  rpn = params[:rpn]
  result = HTTPRestAdapter.new(config[:remote_services][:calculator]).http_get('calculator', rpn)
  result.to_json
end

# Database endpoints
post '/database/tasks' do
  task = params[:task]
  result = HTTPRestAdapter.new(config[:remote_services][:database]).http_post('tasks', task)
  result.to_json
end

get '/database/tasks' do
  result = HTTPRestAdapter.new(config[:remote_services][:database]).http_get('tasks')
  result.to_json
end

get '/database/tasks/:id' do
  id = params[:id]
  result = HTTPRestAdapter.new(config[:remote_services][:database]).http_get('tasks/', id)
  result.to_json
end

delete '/database/tasks/:id' do
  id = params[:id]
  result = HTTPRestAdapter.new(config[:remote_services][:database]).http_delete("tasks/#{id}")
  result.to_json
end
