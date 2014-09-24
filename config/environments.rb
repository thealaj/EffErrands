require 'active_record'
require 'active_record_tasks'
require_relative '../lib/efferrands.rb' 

ActiveRecord::Base.establish_connection(
  :adapter => 'postgresql',
  :database => 'efferrands'
)