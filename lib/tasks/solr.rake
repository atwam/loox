require 'sunspot/server.rb'

class SolrRunner
  class << self
    #
    # Configuration section
    #

    def solr_home
      File.expand_path(File.join(Rails.root, "vendor", "solr"))
    end

    def solr_data_dir
      File.expand_path(File.join(Rails.root, "db", "solr"))
    end

    def log_file
      File.expand_path(File.join(Rails.root, "log", "solr.log"))
    end

    def log_level
      'INFO'
    end

    def pid_dir
      File.expand_path(File.join(Rails.root, "tmp", "pids"))
    end

    def get_server
      server = Sunspot::Server.new
      server.solr_home = solr_home
      server.solr_data_dir = solr_data_dir
      server.log_file = log_file
      server.log_level = log_level
      server.pid_dir = pid_dir
      server
    end
  end
end

namespace :solr do
  desc "Start the local solr server"
  task :start do
    SolrRunner.get_server.start
  end

  desc "Stop a running solr server"
  task :stop do
    SolrRunner.get_server.stop
  end

  desc "Restart a running solr server"
  task :restart do
    server = SolrRunner.get_server
    server.stop
    server.start
  end

  desc "Reindex all existing elements in batch. Can take a while !"
  task :reindex => :environment do
    per_batch = 500

    puts "Removing all elements from solr index"
    Sunspot.remove_all!(Element)
    puts "Adding elements in batches of #{per_batch}."
    count = Element.all.count
    puts "Total #{count} elements to index"

    offset = 0
    counter = 1
    while(offset < count)
      records = Element.skip(offset).limit(per_batch)
      Sunspot.index(records)
      Sunspot.commit
      offset += records.count
      puts "Done #{offset} rows"
    end

    puts "Done reindexing elements"
  end


end
