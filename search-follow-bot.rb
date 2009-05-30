
#Add lib/ to path
curr_path = File.dirname(__FILE__)
$:.unshift("#{curr_path}/lib")

require 'config_store'
require 'twitter'

class SearchFollow
  attr_accessor :twitter, :config
  
  def initialize(config)
    httpauth = Twitter::HTTPAuth.new(config['username'], config['password'])
    self.twitter = Twitter::Base.new(httpauth)
    self.config = config
    process
  end
    
  def process  
    config['search_words'].each do |term|
      Twitter::Search.new.geocode(config['geocode'][0], config['geocode'][1], '750mi').containing("#{term}").fetch().results.each do |update|
        begin
          out "Found user: #{update['from_user']}(id: #{update['from_user_id']}) with the tweet: #{update['text']}"
          out "Starting to follow..."
          twitter.friendship_create(update['from_user'], true)
          out "Done!"
          sleep 0.1
        rescue Twitter::NotFound
          out "User ID not found correctly, trying next"
          sleep 0.1 and next
        rescue Twitter::General => e
          out "Error: #{e.inspect}"
          sleep 0.1 and next
        end
      end
    end
  rescue Twitter::RateLimitExceeded, Net::HTTPServerError
    out "Rate limit exceeded, try spacing out cron intervals!"
  end
  
  def text_contains_any_of(text, array)
    array.each do |element|
      return true unless text.downcase.grep(/#{element.downcase}/).empty?
    end
    false
  end
  
  def out(text)
    puts "#{Time.now}: #{text}" if config['debug']
  end
end

config = ConfigStore.new(File.join(File.dirname(__FILE__), "config.yml"))
SearchFollow.new(config)