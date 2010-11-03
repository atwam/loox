source 'http://rubygems.org'

gem 'rails', '~> 3.0'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'


# Use unicorn as the web server
# gem 'unicorn'
gem "haml"
gem "hpricot"
gem "jquery-rails"
gem "will_paginate", "~> 3.0.pre2"
# Deploy with Capistrano
# gem 'capistrano'

# To use debugger
# gem 'ruby-debug'

# Bundle the extra gems:
gem "mongoid", "2.0.0.beta.17"
gem "bson_ext", "1.0.4"
gem "resque-mongo", :require=>'resque'

gem "sunspot"
gem "sunspot_mongoid", :path=>"~/Dev/forks/sunspot_mongoid"

# Used by core parsers
gem "shared-mime-info", :git=>"http://github.com/hanklords/shared-mime-info.git"
# Used by other parsers
gem "ruby-mp3info" # Parser::Audio::Mp3Parser
gem "rmagick" # Parser::Image::StdImageParser

#gem "mongo_queue", :git=>"git://github.com/Skiz/mongo_queue.git"
# gem 'bj'
# gem 'nokogiri', '1.4.1'
# gem 'sqlite3-ruby', :require => 'sqlite3'
# gem 'aws-s3', :require => 'aws/s3'
gem 'awesome_print', :require => 'ap'

# Bundle gems for certain environments:
# gem 'rspec', :group => :test
group :test do
  #gem 'webrat'
  gem 'rspec'
  gem "rspec-rails", ">= 2.0.0.beta.20"
end
group :development do
  gem 'rb-inotify'
  gem "wirble"
  gem "rdoc"
end
