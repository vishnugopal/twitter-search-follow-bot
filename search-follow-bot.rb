
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
      #out "Analyzing user: #{update['user']['screen_name']}, update: #{update['text']}..."
      if relevant_update?(update)
        pp update['user']
        out "Found user: #{update['user']['screen_name']}(id: #{update['user']['id']}) with the tweet: #{update['text']}"
        out "Starting to follow..."
        twitter.friendship_create(update['user']['id'], true) #Start following!
        out "Done!"
      end
    end
  rescue Twitter::RateLimitExceeded
    out "Rate limit exceeded, try spacing out cron intervals!"
  end
  
  def text_contains_any_of(text, array)
    array.each do |element|
      return true unless text.downcase.grep(/#{element.downcase}/).empty?
    end
    false
  end
  
  def relevant_update?(update)
    if text_contains_any_of(update['text'], config['search_words'])
      out "Text matched, let's see if location matches..." 
      out "(was analyzing user: #{update['user']['screen_name']}, location: #{update['user']['location']}, update: #{update['text']})"
      if indian_user?(update['user'])
        out "User found to be indian too, great!"
        out "(was analyzing user: #{update['user']['screen_name']}, location: #{update['user']['location']}, update: #{update['text']})"
        return true
      end
    end
    false
  end
      
  
  def indian_user?(user)
    if text_contains_any_of(user['location'], config['location_match'])
      out "User #{user['screen_name']} location matched #{user['location']}, tagging as Indian."
      return true 
    end
    if config['check_in_tweeple_india_directory']  
      return in_tweeple_india_directory?(user)
    end
    false
  end
  
  # This works by checking for friendship between tweeple_india and the current user
  def in_tweeple_india_directory?(user)
    if twitter.friendship_exists?("tweepleindia", user['screen_name'])
      out "User #{user['screen_name']} found in tweeple directory. Tagging as indian"
      return true
    end
    false
  end
  
  def out(text)
    puts "#{Time.now}: #{text}" if config['debug']
  end
end

config = ConfigStore.new(File.join(File.dirname(__FILE__), "config.yml"))
SearchFollow.new(config)