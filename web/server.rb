require_relative '../lib/efferrands.rb'
require 'sinatra'
require 'pry-byebug'
require 'unirest'
require 'dotenv'

class EffErrands::Server < Sinatra::Application

  set :bind, "0.0.0.0"
  Dotenv.load

  get '/' do
    #home page
    @@user_items = []
    @@start_location = []
    @@end_location = []
    erb :index
  end

  #for index, use this
  post '/add-items' do
    #sets @error to an empty string, to be ignored if there is no error
    @error = ''

    #check if start name or start address is empty and has not already been entered
    if (params['start_name'].empty? || params['start_address'].empty?) && @@start_location.empty?
      @error = 'Please add a starting location with name and address.'

    #check if either dest name or address is empty
    elsif params['dest_name'].empty? || params['dest_address'].empty?
      @error = 'Please add a destination with name and address.'

    #if start location has not been changed and new destination has been added
    elsif params['start_name'].empty? && params['start_address'].empty?
      #add each item one at a time
      @@user_items << [params['dest_name'], params['dest_address']] # 'Target', '2300 W Ben White Blvd, Austin, TX'

    #if start location has been updated and new destination has been added  
    else
      @@start_location = [params['start_name'], params['start_address']]
      #add each item one at a time
      @@user_items << [params['dest_name'], params['dest_address']] # 'Target', '2300 W Ben White Blvd, Austin, TX'
    end

    #if end_home checkbox is checked, add start location as end location
    if params['end_home'] == 1
      @@end_location = [params['start_name'], params['start_address']]

    #if there is information entered in just one field, create error
    elsif (!params['end_name'].empty? && params['end_address'].empty?) || (params['end_name'].empty? && !params['end_address'].empty?)
      @error = 'Please add an ending location with name and address.'

    #if both fields are filled out, set end location
    elsif !params['end_name'].empty? && !params['end_address'].empty?
        @@end_location = [params['end_name'], params['end_address']]
    end

    #end_name, end_address
    #end_home is the checkbox

    erb :index
  end

  post '/route' do
    #@@user_items = [['Target', '2300 W Ben White Blvd, Austin, TX'], [ 'HEB', '1000 E 41st St Austin, TX 78751']]
    #@@start_location = ['DevHouse', '1803 E 18th Street, Austin, TX']
    #@@end_location = ['MakerSquare Brazos', '800 Brazos St, Austin, TX']

    #create address hash
    @@address = {:endpoint => false}

    #create array for origins key
    @@address[:origins] = @@user_items.map {|x| x.last.gsub(/,/, '').gsub(/\s/, '+')}
    @@address[:origins].unshift(@@start_location.last.gsub(/,/, '').gsub(/\s/, '+'))

    #create array for destinations key
    @@address[:destinations] = @@user_items.map {|x| x.last.gsub(/,/, '').gsub(/\s/, '+')}

    if !@@end_location.empty?
      @@address[:destinations].push(@@end_location.last.gsub(/,/, '').gsub(/\s/, '+'))
      @@address[:endpoint] = true
    end

  end

  get '/api_request' do
    en_url = URI.encode('https://maps.googleapis.com/maps/api/distancematrix/json?origins=' + @@address[:origins].join("|") + '&destinations='+ @@address[:destinations].join("|") + '&units=imperial&key=' + ENV['GOOGLE_MAPS_KEY'])
    response = Unirest.get (en_url)
    data = response.body
    algo_data = []
    i = 0
    while i < data['origin_addresses'].length
      org_ary = []
      j = 0
      while j < data['destination_addresses'].length
        dest_ary = []
        dest_ary << data['destination_addresses'][j]
        dest_ary << data['rows'][i]['elements'][j]['distance']['value']
        org_ary << dest_ary
        j += 1
      end
      org_hash = {}
      org_hash[data['origin_addresses'][i]] = org_ary
      algo_data << org_hash
      i += 1
    end

  end


  run! if __FILE__ == $0
end


