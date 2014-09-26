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
    
    erb :index 
  end

  #for index, use this
  post '/add-items' do
    #sets @error to an empty string, to be ignored if there is no error
    @error = ''

    #check if start name or start address is empty and has not already been entered
    if (params['start_name'].nil? || params['start_address'].nil?) && @@start_location == []
     @error = 'Please add a starting location with name and address.'

    elsif @@start_location == []
      @@start_location = [params['start_name'], params['start_address']]
    end

     
    if !params['dest_name'].nil? && !params['dest_address'].nil?
      @@user_items << [params['dest_name'], params['dest_address']] 

    elsif params['dest_name'] == '' || params['dest_address'] == ''
      @error = 'Please add a destination with name and address.'
    end
    

    start_dest = @@start_location
    dests = @@user_items
    binding.pry

    erb :index, :locals => {start_dest: start_dest, dests: dests}
  end

  post '/route' do
    #@@user_items = [['Target', '2300 W Ben White Blvd, Austin, TX'], [ 'HEB', '1000 E 41st St Austin, TX 78751']]
    #@@start_location = ['DevHouse', '1803 E 18th Street, Austin, TX']
    #@@end_location = ['MakerSquare Brazos', '800 Brazos St, Austin, TX']

    #create address hash
    @@address = {}

    #create array for origins key
    @@address[:origins] = @@user_items.map {|x| x.last.gsub(/,/, '').gsub(/\s/, '+')}
    @@address[:origins].unshift(@@start_location.last.gsub(/,/, '').gsub(/\s/, '+'))

    #create array for destinations key
    @@address[:destinations] = @@user_items.map {|x| x.last.gsub(/,/, '').gsub(/\s/, '+')}
    @@address[:destinations].push(@@start_location.last.gsub(/,/, '').gsub(/\s/, '+'))

    start_dest = @@start_location
    dests = @@user_items
    addresses = @@address    

    erb :route, :locals => {start_dest: start_dest, dests: dests, addresses: addresses}

  end
  #@@addresses = {:endpoint=>true, :origins=>["1803+E+18th+Street+Austin+TX", "2300+W+Ben+White+Blvd+Austin+TX", "1000+E+41st+St+Austin+TX+78751"], :destinations=>["2300+W+Ben+White+Blvd+Austin+TX", "1000+E+41st+St+Austin+TX+78751", "800+Brazos+St+Austin+TX"]}
 

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


