# We have to explicitely require shared-mime-info since MIME is a module
# and rails autoloading seems to struggle loading it properly
require 'shared-mime-info'

class Element
  include Mongoid::Document
  include Sunspot::Mongoid

  field :parent_id
  # Filename or dirname
  field :name
  # Path relative to collection base
  field :path
  # Collection id
  field :collection_id
  # Mime type for this field
  field :mime_type
  # A hash of the file, nil when directories.
  # Should be almost surely unique for the file
  field :content_hash
  # List of fields to index in full_text in the search engine
  field :indexed_fields, :type=>Array, :default => []

  index :path, :unique => true
  index :parent_id
  index :content_hash

  def self.find_by_path(path)
    self.first(:conditions=>{:path=>path})
  end

  def volatile
    @volatile ||= {}
  end

  def full_path
    volatile[:full_path] ||= File.join(col.base_path, path)
  end

  # Read only associations, used for display but not intended to be modified.
  # Especially not using mongoid standard association to avoid having any related element to be saved
  # When this one is saved. Probably dumb, will see later to make something better

  # Can't be called collection, would conflict with mongo::document
  def col
    volatile[:collection] ||= Collection.find(collection_id)
  end
  def parent
    parent_id && (volatile[:parent] ||= Element.find(parent_id))
  end
  def children
    self.class.where(:parent_id=>id)
  end

  def mime_type
    MIME[self[:mime_type]]
  end

  #
  # Search definitions and related stuff
  # Note : Sunspot::Rails defaults apply here : auto_index is true, auto_remove is true
  #
  searchable do
    text :name, :stored => true

    text :indexed_fields do
      self[:indexed_fields] = (self[:indexed_fields] || []).uniq
      self[:indexed_fields].collect{|field| self[field]}.compact.join(' -- ')
    end

    string :mime_type, :stored => true
    string :media do
      self[:mime_type] && self[:mime_type].split('/').first
    end

    # dynamic_text :custom_fields do
    #   self[:indexed_fields] = (self[:indexed_fields] || []).uniq
    #   h = self[:indexed_fields].inject({}) do |hash, field|
    #     value = self[field]
    #     hash[field] = value if value
    #     hash
    #   end
    #   h
    # end
  end

  def set_indexed_field(field, value)
    add_indexed_field(field)
    self[field] = value
  end
  def add_indexed_field(fields)
    self[:indexed_fields] = [self[:indexed_fields],fields].flatten.compact
  end

  #
  # Utility functions
  #
  def self.logger
    @@logger ||= Logger.new("#{RAILS_ROOT}/log/#{self.class.name}.log")
  end
  def logger
    @@loger
  end
end
