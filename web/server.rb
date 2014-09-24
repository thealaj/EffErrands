require_relative '../lib/efferrands.rb'
require 'sinatra'
require 'pry-byebug'

class EffErrands::Server < Sinatra::Application

  set :bind, "0.0.0.0"

  get '/' do
    erb :index
  end


  run! if __FILE__ == $0
end

