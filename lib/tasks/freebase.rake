#! /bin/env ruby
require 'ansi'
require 'net/http'
require 'uri'
require 'open3'
require 'fileutils'

class CanceledByUserException < Exception
end

SUBFILES =
  %w(tv_director tv_actor tv_series_episode
    tv_guest_personal_appearance tv_guest_role tv_genre
    tv_character tv_episode_segment tv_series_season)
.collect{|s| "tv/" + s} +
  %w(artist live_album soundtrack album single genre
    album_release_type musical_group track release_component
    track_contribution release composer songwriter group_member
    concert group_membership)
.collect{|s| "music/" + s} +
  %w(writer actor film_collection film_awards_ceremony
    content_rating film_critic producer film_series
    film_crewmember film music_contributor film_location
    film_featured_song person_or_entity_appearing_in_film film_genre
    film_subject personal_film_appearance_type film_character
    personal_film_appearance director)
.collect{|s| "film/" + s}

BASE_URL_BROWSE="http://download.freebase.com/datadumps/latest/browse/"
COLLECTION_NAME_DATA="freebase_data"


namespace :loox do
  namespace :freebase do
    BASE_PATH=File.expand_path('../../tmp/freebase', __FILE__)

    base_path = File.expand_path('tmp/freebase', Rails.root)

    task :setup => :environment do
      FileUtils.mkdir_p base_path unless File.exists?(base_path)
    end

    namespace :data do
      desc "Download files from freebase and extract them in a temp dir"
      task :download => :setup do
        md5_url = BASE_URL_BROWSE + "MD5SUMS"
        puts "Downloading md5sum file from #{ANSI.green(md5_url)}"

        md5 = Net::HTTP.get URI.parse(md5_url)
        md5 = Hash[*md5.lines.collect{|l| s=l.split; [s[1],s[0]]}.flatten]

        SUBFILES.group_by {|s| s.split('/')[0]}.each do |category, files|
          basename = category + ".tar.bz2"
          url = BASE_URL_BROWSE + basename
          local_dest = File.expand_path(basename, base_path)
          should_have_md5 = md5[basename]
          unless should_have_md5
            raise "Couldn't find md5 for #{basename} in #{md5_url}"
          end

          Loox::Freebase::Downloader.download_file_if_needed(url, local_dest, should_have_md5)
        end
      end

      desc "Extract tsv files from .tar.bz2 freebase files"
      task :extract => :setup do
        SUBFILES.group_by {|s| s.split('/')[0]}.each do |category, files|
          basename = category + ".tar.bz2"
          local_dest = File.expand_path(basename, base_path)

          unless File.exist?(local_dest)
            raise "File #{ANSI.green(local_dest)} not found, can't extract !"
          end

          Loox::Freebase::Downloader.extract_file(local_dest, base_path, files.collect{|s| s+".tsv"})
        end
      end

      desc "Download, extract and import data files"
      task :import => :setup do
        # We use this ugly trick to get the db from mongoid, already configured in the environment
        db = Element.db
        collection = Loox::Freebase::DbImporter.create_collection(db, COLLECTION_NAME_DATA)

        SUBFILES.each do |sub_file|
          file_path = File.expand_path(sub_file, base_path)
          Loox::Freebase::DbImporter.import_tsv_data_file_local(file_path + ".tsv", collection)
        end

        #Loox::Freebase::DbImporter.post_process
      end

      desc "Download, extract and import data files"
      task :run => [:download, :extract, :import] do
      end
    end

  end
end

module Loox
  module Freebase
    class Downloader
      def self.download_file(url, output_path)
        uri = URI.parse(url)

        Net::HTTP.start(uri.host) do |http|
          http.request_get(uri.request_uri) do |resp|

            dl = 0
            pbar = nil

            total_l = resp.content_length
            puts "Downloading #{total_l} bytes from #{url}"
            #pbar = ProgressBar.new(File.basename(uri.request_uri), total_l)
            pbar = ANSI::Progressbar.new(File.basename(uri.request_uri), total_l, STDOUT)
            pbar.transfer_mode

            File.open(output_path, "w:ASCII-8BIT") do |outfile|
              resp.read_body do |segment|
                dl += segment.size
                pbar.set(dl)
                outfile.write(segment)
              end
            end
            pbar.finish
            puts
          end
        end
      end

      def self.download_file_if_needed(url, local_dest, md5)
        puts "About to download #{ANSI.green(local_dest)}"
        if File.exists?(local_dest)
          puts "The file already exists, checking md5"

          local_md5 = md5sum(local_dest)
          if local_md5 == md5
            puts "Local file has a matching md5, no need to download again"
            return
          end
          puts "File has md5 #{ANSI.red(local_md5)}, should be #{ANSI.red(md5)}"
          puts "Removing #{ANSI.green(local_dest)} and downloading again"
          File.unlink(local_dest)
        end

        download_file(url, local_dest)

        puts "Checking md5"
        local_md5 = md5sum(local_dest)
        if local_md5 != md5
          raise "Error : file #{local_dest} md5 doesn't match target #{url} md5"
        end
      end

      def self.md5sum(local_file)
        `md5sum #{local_file}`.split[0]
      end

      # Extraction stuff
      def self.extract_file(path, destdir, subfiles)
        puts "Expanding #{ANSI.green(path)} to get #{ANSI.green(subfiles.length)} subfiles."

        cmd = "tar -xvjf #{path} "
        cmd += "-C #{destdir} "
        cmd += subfiles.join(" ")

        #puts "Executing #{italic(cmd)}"
        pbar = ANSI::Progressbar.new("Extracting", subfiles.length, STDOUT)
        Open3.popen3(cmd) do |stdin, stdout, stderr|
          stdout.each do |line|
            pbar.title = File.basename(line).chomp
            pbar.inc
          end
        end
        pbar.finish
        puts
      end
    end

    class DbPkFactory
      def create_pk(row)
        row['_id'] ||= Mongo::ObjectID.new
        row
      end
    end

    class DbImporter
      FREEBASE_ID_FIELD = "_id"
      BATCH_SIZE=1000

      def self.create_collection(db, collection)
        puts "Creating collection #{ANSI.green(collection)}"
        if db.collection_names.include?(collection)
          puts "Collection already exists !"
          puts "Type #{ANSI.green("yes")} to overwrite, anything else to quit."
          raise CanceledByUserException unless $stdin.gets.chomp == "yes"

          db.drop_collection(collection)
        end

        #col = db.create_collection(collection, :pk=>DbPkFactory.new)
        col = Mongo::Collection.new(db, collection, DbPkFactory.new)
        #col.create_index(FREEBASE_ID_FIELD)

        col
      end

      def self.import_tsv_data_file_local(file, collection)
        fields, processors = analyze_fields(file, collection.name)

        total_size = File.size(file)
        done_size = 0
        done_items = 0

        puts "Importing #{total_size} bytes from #{ANSI.green(file)} into mongo db collection #{ANSI.green(collection.name)}"
        pbar = ANSI::Progressbar.new(File.basename(file), total_size)
        pbar.transfer_mode

        File.open(file) do |f|
          header = f.gets.chomp
          done_size += header.length

          batch = Array.new(BATCH_SIZE)
          while (line = f.gets.chomp)
            line_values = line.split("\t")
            processors.each {|processor| processor.call(line_values)}

            obj = Hash[fields.zip(line_values)]
            puts obj
            batch << obj

            if (batch.length == BATCH_SIZE)
              collection.insert(batch)
              batch = []
            end

            done_size += line.length
            done_items += 1
            pbar.set(done_size)
          end

          collection.insert(batch)
        end
        pbar.finish
        puts "Imported #{ANSI.yellow(done_items)} items from #{ANSI.green(file)} into #{ANSI.green(collection.name)} collection"
      end

      def self.analyze_fields(file, collection_name)
        puts "Analyzing fields for file #{ANSI.green(file)}"

        f = File.open(file)
        header = f.gets.chomp
        fields = header.split("\t").collect do |field|
          field.gsub!(" ","_")
          field == "id" ? FREEBASE_ID_FIELD : field
        end

        first_lines = []
        # Check first 10 lines, in case some may have nil as a value for the field
        10.times { first_lines << f.gets.split("\t") }

        processors = []
        fields.each_index do |i|
          if fields[i] != FREEBASE_ID_FIELD && first_lines.any?{|l| !l[i].nil? && l[i].starts_with?('/m/')}
            processors << get_field_splitter(i, collection_name)
          end
        end

        f.close

        [fields, processors]
      end

      def self.get_field_splitter(index, collection_name)
        Proc.new do |flds|
          if flds[index]
            flds[index]=flds[index].split(',').collect do |id|
              BSON::DBRef.new(collection_name, id)
            end
          end
        end
      end

      def self.import_tsv_data_file_native(file, collection) 
        # Parse fields and replace id with _id
        fields = []
        File.open(file) do |f|
          fields = f.gets.split.collect do |field|
            field.gsub!(" ","_")
            field == "id" ? FREEBASE_ID_FIELD : field
          end
        end
        puts "Importing #{ANSI.green(file)} into mongo db"

        cmd = "mongoimport -d #{collection.db.name} " +
          "-c #{collection.name} " +
          "-type tsv --headerline " +
          "-f #{fields.join(',')} " +
          file

        puts "Running #{ANSI.green(cmd)}"
        Open3.popen3(cmd) do |stdin, stdout, stderr|
          stdout.each do |line|
            puts line
          end
        end
      end
    end
  end
end

class FreebaseImporter
  # List of files from freebase we shall load
  attr_accessor :sub_files

  def initialize
    # Ensure we'll have a working directory
    Dir.mkdir(BASE_PATH) unless Dir.exists?(BASE_PATH)
  end

  # Database stuff
  def connect_db
    file_name = File.expand_path('../../config/mongoid.yml', __FILE__)
    require 'pp'
    pp ENV
    @settings = YAML.load(ERB.new(File.new(file_name).read).result)[ENV['RACK_ENV']]

    Mongo::Connection.new(@settings[:host], @settings[:port]).db(@settings[:database])
  end

  def run
    #download_and_extract_category_files(@sub_files)


  end
end


#importer = FreebaseImporter.new
#importer.sub_files = subfiles
# Eventually download the file
#Import from an existing big file.
#That's very slow because freebase is using bzip2 for compression
#importer.import_data_file(File.expand_path('../../tmpdata/freebase-datadump-tsv.tar.bz2', __FILE__), subfiles)
#importer.run
