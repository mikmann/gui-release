# frozen_string_literal: true

require 'sinatra'
require 'json'

# index or start site
get '/gui' do
  erb :index, locals: params, layout: false
end

# send user data to lexer
post '/lexer/send_expr' do
  # follows RFC 3986, which requires spaces to be encoded to %20
  input = ERB::Util.url_encode(params[:name])

  redirect "http://localhost:5000/lexer/rpn?name=#{input.to_json}"
end

# send user data to lexer
get 'calculator/rpn' do
  # follows RFC 3986, which requires spaces to be encoded to %20
  input = ERB::Util.url_encode(params[:name])

  redirect "http://localhost:3000/calculator/rpn?name=#{input.to_json}"
end

# gets the expression in rpn backs
get '/gui/rpn' do
  erb :user_input, locals: params, layout: :layout
end

# gets the expression in rpn backs
get '/gui/result' do
  erb :user_input, locals: params, layout: :layout
end
