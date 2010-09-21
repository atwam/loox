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
  # A hash of the file, nil when directories.
  # Should be almost surely unique for the file
  field :hash

  index :path, :unique => true
  index :parent_id
  index :hash

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

  #
  # Search definitions and related stuff
  # Note : Sunspot::Rails defaults apply here : auto_index is true, auto_remove is true
  #
  searchable do
    text :name
  end

end
