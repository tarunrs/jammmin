require 'rubygems'
require 'sinatra'
require 'yaml'

# Loads all the file under folder lib
`ls lib`.split("\n").each do |file| load("lib/#{file}") end

set :public, File.dirname(__FILE__) + '/public'

include Utils

helpers do
  load('helpers/all.rb')
end

get '/' do
  "Welcome to jamMm.in"
end


# Url Catcher for .css files. If not found, it will look for a static file.
get '/stylesheets/*.css' do
  filename = params[:splat][0]
  erb :"stylesheets/#{filename}"
end


# Loads all the account urls e.g: /account/home
load 'urls/account.rb'

# Loads all the profile urls eg: /user1, /user2
load 'urls/profile.rb'