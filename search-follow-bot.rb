
#Add lib/ to path
curr_path = File.dirname(__FILE__)
$:.unshift("#{curr_path}/lib")

require 'config_store'
require 'twitter'
require 'twitter_public_timeline'
require 'pp'


class SearchFollow
  attr_accessor :twitter, :config
  
  def initialize(config)
    httpauth = Twitter::HTTPAuth.new(config['username'], config['password'])
    self.twitter = Twitter::Base.new(httpauth)
    self.config = config
    process
  end
    
  def process
    twitter.public_timeline.each do |update|
      if text_contains_any_of(update['text'], config['search_words'])
        out "Found user: #{update['user']['screen_name']}(id: #{update['user']['id']}) with the tweet: #{update['text']}"
        out "Starting to follow..."
        twitter.friendship_create(update['user']['id'], true) #Start following!
        out "Done!"
      end
    end
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