require_relative '../lib/efferrands.rb'
require 'sinatra'
require 'pry-byebug'

class EffErrands::Server < Sinatra::Application

  set :bind, "0.0.0.0"
  @@user_items = []
  @@start_location = []

  get '/' do
    #home page
    erb :index
  end

  #for index, use this
  post '/add-items' do
    #sets @error to an empty string, to be ignored if there is no error
    @error = ''

    #check if start name or start address is empty and has not already been entered
    if (params[start_name].empty? || params[start_address].empty?) && @@start_location.empty?
      @error = 'Please add a starting location with name and address.'

    #check if either dest name or address is empty
    elsif params[dest_name].empty? || params[dest_address].empty??
      @error = 'Please add a destination with name and address.'

    #if start location has not been changed and new destination has been added
    elsif params[start_name].empty? && params[start_address].empty?
      #add each item one at a time
      @@user_items << [params[dest_name], params[dest_address]] # 'Target', '2300 W Ben White Blvd, Austin, TX'

    #if start location has been updated and new destination has been added  
    else
      @@start_location = [params[start_name], params[start_address]]
      #add each item one at a time
      @@user_items << [params[dest_name], params[dest_address]] # 'Target', '2300 W Ben White Blvd, Austin, TX'
    end

    #end_name, end_address
    #end_home is the checkbox

    erb :index
  end

  post '/route' do
    #@@user_items = [['Target', '2300 W Ben White Blvd, Austin, TX'], [ 'HEB', '1000 E 41st St Austin, TX 78751']]

    #create address hash
    @@address = {:endpoint = false}

    #create array for origins key
    @@address[:origins] = @@user_items.map {|x| x.last.gsub(/,/, '').gsub(/\s/, '+')}
    @@address[:origins].unshift(@@start_location.last.gsub(/,/, '').gsub(/\s/, '+'))

    #create array for destinations key
    @@address[:destinations] = @@user_items.map {|x| x.last.gsub(/,/, '').gsub(/\s/, '+')}

    if @@end_location
      @@address[:destinations].push(@@end_location.last.gsub(/,/, '').gsub(/\s/, '+'))
      @@addres[:endpoint] = true
    else 

    end




    #turn @@user_items into a hash 
    @@user_items.map

  end


  run! if __FILE__ == $0
end

