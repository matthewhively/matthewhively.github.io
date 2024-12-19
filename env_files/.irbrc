require 'rubygems'

# Some commonly used gemfiles
require 'amazing_print'
require 'json'
puts "Auto-required: amazing_print, json"
puts 'REM: use "_" to quickly reference the previous command output'

# turns on logging within ruby console
if ENV.include?('RAILS_ENV') && ENV["RAILS_ENV"] == 'development'
    ActiveRecord::Base.logger = Logger.new(STDOUT)
    ActiveRecord::Base.connection_pool.clear_reloadable_connections!
end

# To view source of:
#   Rails.logger
# use:
#   Rails.method(:logger).source
#
# https://stackoverflow.com/a/46966145/6716352
class Method
  def source(limit=10)
    file, line = source_location
    if file && line
      puts "#{file} (#{line-1}:#{line-1+limit})\n#{'-'*30}"
      puts IO.readlines(file)[line-1,limit]
    else
      puts nil
    end
  end
end

