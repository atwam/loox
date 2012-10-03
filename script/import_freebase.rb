#! /bin/env ruby
require File.expand_path('../../config/boot.rb', __FILE__)

require 'ansi'
require 'erb'
require 'net/http'
require 'uri'
require 'open3'
require 'mongo'

class CanceledByUserException < Exception
end

class FreebaseImporter
  include ANSI::Code

  BASE_URL_BROWSE="http://download.freebase.com/datadumps/latest/browse/"
  BASE_PATH=File.expand_path('../../tmp/freebase', __FILE__)

  COLLECTION_NAME_DATA="freebase_data"

  # List of files from freebase we shall load
  attr_accessor :sub_files

  def initialize
    # Ensure we'll have a working directory
    Dir.mkdir(BASE_PATH) unless Dir.exists?(BASE_PATH)
  end

  # Downloading stuff
  
  def download_file(url, output_path)
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

        File.open(output_path, "w") do |outfile|
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

  def download_file_if_needed(url, local_dest, md5)
    puts "About to download #{green(local_dest)}"
    if File.exists?(local_dest)
      puts "The file already exists, checking md5"

      local_md5 = md5sum(local_dest)
      if local_md5 == md5
        puts "Local file has a matching md5, no need to download again"
        return
      end
      puts "File has md5 #{red(local_md5)}, should be #{red(md5)}"
      puts "Removing #{green(local_dest)} and downloading again"
      File.unlink(local_dest)
    end

    download_file(url, local_dest)

    puts "Checking md5"
    local_md5 = md5sum(local_dest)
    if local_md5 != md5
      raise "Error : file #{local_dest} md5 doesn't match target #{url} md5"
    end
  end

  def md5sum(local_file)
    `md5sum #{local_file}`.split[0]
  end

  # Extraction stuff
  def extract_file(path, subfiles)
    puts "Expanding #{green(path)} to get #{green(subfiles.length)} subfiles."

    cmd = "tar -xvjf #{path} "
    cmd += "-C #{BASE_PATH} "
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

  # Database stuff
  def connect_db
    file_name = File.expand_path('../../config/mongoid.yml', __FILE__)
    require 'pp'
    pp ENV
    @settings = YAML.load(ERB.new(File.new(file_name).read).result)[ENV['RACK_ENV']]

    Mongo::Connection.new(@settings[:host], @settings[:port]).db(@settings[:database])
  end

  def create_collection(db, collection)
    puts "Creating collection #{collection}"
    if db.collection_names.include?(collection)
      puts "Collection already exists !"
      puts "Type #{green("yes")} to overwrite, anything else to quit."
      raise CanceledByUserException unless gets.chomp == "yes"

      db.drop_collection(collection)
    end

    col = db.create_collection(collection)
    #col.create_index("id")

  end

  def import_tsv_data_file(file, collection) 
    # Parse fields and replace id with _id
    fields = []
    File.open(file) do |f|
      fields = f.gets.split.collect do |field|
        field.gsub!(" ","_")
        field == "id" ? "_id" : field
      end
    end
    puts "Importing #{green(file)} into mongo db"

    cmd = "mongoimport -d #{collection.db.name} " +
      "-c #{collection.name} " +
      "-type tsv --headerline " +
      "-f #{fields.join(',')} " +
      file

    puts "Running #{green(cmd)}"
  end

  # Main routines 
  def download_and_extract_category_files(subfiles)
    puts "Downloading md5sum file"
    md5_url = BASE_URL_BROWSE + "MD5SUMS"
    md5 = Net::HTTP.get URI.parse(md5_url)
    md5 = Hash[*md5.lines.collect{|l| s=l.split; [s[1],s[0]]}.flatten]

    subfiles.group_by {|s| s.split('/')[0]}.each do |category, files|
      basename = category + ".tar.bz2"
      url = BASE_URL_BROWSE + basename
      local_dest = File.expand_path(basename, BASE_PATH)
      should_have_md5 = md5[basename]
      unless should_have_md5
        raise "Couldn't find md5 for #{basename} in #{md5_url}"
      end

      download_file_if_needed(url, local_dest, should_have_md5)
      extract_file(local_dest, files.collect{|s| s+".tsv"})
    end
  end

  def run
    #download_and_extract_category_files(@sub_files)

    @db = connect_db
    collection = create_collection(db, COLLECTION_NAME_DATA)

    @sub_files.each do |sub_file|
      import_tsv_data_file(sub_file)
    end

  end
end

subfiles =
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

importer = FreebaseImporter.new
importer.sub_files = subfiles
# Eventually download the file
#Import from an existing big file.
#That's very slow because freebase is using bzip2 for compression
#importer.import_data_file(File.expand_path('../../tmpdata/freebase-datadump-tsv.tar.bz2', __FILE__), subfiles)
importer.run
