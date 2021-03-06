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

    address = @@address
    # binding.pry

    redirect '/api_request_waypoints'
  end
  #@@address = {:origins=>["1803+E+18th+Street+Austin+TX", "2300+W+Ben+White+Blvd+Austin+TX", "1000+E+41st+St+Austin+TX+78751"], :destinations=>["2300+W+Ben+White+Blvd+Austin+TX", "1000+E+41st+St+Austin+TX+78751", "1803+E+18th+Street+Austin+TX"]}
 
  # USING BEN'S AWESOME ALGORITHM:
  # get '/api_request' do
  #   # Make API call to Google:
  #   en_url = URI.encode('https://maps.googleapis.com/maps/api/distancematrix/json?origins=' + @@address[:origins].join("|") + '&destinations='+ @@address[:destinations].join("|") + '&units=imperial&key=' + ENV['GOOGLE_MAPS_KEY'])
  #   # Recieve code vomit:
  #   response = Unirest.get (en_url)
  #   # Orders code vomit in reasonable JSON:
  #   data = response.body
  #   # Empty hash for Ben's data:
  #   algo_data = []
  #   i = 0
  #   # Loop through origin addresses:
  #   while i < data['origin_addresses'].length
  #     org_ary = []
  #     j = 0
  #     # Loop through destination addresses:
  #     while j < data['destination_addresses'].length
  #       dest_ary = []
  #       # Push each destination into the array:
  #       dest_ary << data['destination_addresses'][j]
  #       # Push each destination's distance into the array:
  #       dest_ary << data['rows'][i]['elements'][j]['distance']['value']
  #       # Push the distination array into the origins array:
  #       org_ary << dest_ary
  #       j += 1
  #     end
  #     org_hash = {}
  #     # Create a hash of origin address keys and their data values:
  #     org_hash[data['origin_addresses'][i]] = org_ary
  #     # Push hashes into Ben's array:
  #     algo_data << org_hash
  #     i += 1
  #   end

  # end

  #USING GOOGLE'S SHITTY ALGORITHM:
  #data['routes'].first['legs'].first['steps'].first['html_instructions']
  get '/api_request_waypoints' do
    # Make API call to google maps: 
    new_url = URI.encode('https://maps.googleapis.com/maps/api/directions/json?origin=' + @@address[:origins].first + '&destination=' + @@address[:origins].first + '&waypoints=optimize:true|' + @@address[:origins][1..-1].join("|") + '&key=' + ENV['GOOGLE_MAPS_KEY'].to_s)
    ordered_response = Unirest.get (new_url)
    # Put the API response in some sort of order:
    data = ordered_response.body

    # Creates some containers for the data:
    points_hash = {}
    each_stop = []
    # Adds all of the addresses into an array in the order sorted by Google:
    data['routes'].first['legs'].each_index do |i|
      each_stop << "#{data['routes'].first['legs'][i]['start_address']}: #{data['routes'].first['legs'][i]['distance']['text']}"
    end
    ## Adds the start point back to the end of the array:
    # each_stop.push(data['routes'].first['legs'].first['start_address'])
    # Adds a key for each address value denoting the order of the trip:
    each_stop.each_index do |i|
      points_hash[i + 1] = each_stop[i]
    end

    index_order = data['routes'].first['waypoint_order']
    start_dest = @@start_location
    dests = @@user_items
    addresses = @@address  
    names = []

    i =0
    while i < dests.length do
      names << dests[index_order[i]].first
      i +=1
    end

    names.unshift(start_dest.first)

    erb :route, :locals => {start_dest: start_dest, points: points_hash, names: names}

  end


  run! if __FILE__ == $0
end


