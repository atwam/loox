class Collection
  include Mongoid::Document

  field :name
  field :base_path

  references_many :elements, :dependent => :destroy

  def base_element
    elements.find(:first, :conditions=>{:path=>'/'})
  end

  def enqueue
    Rails.logger.info("Queuing collection #{name}:#{id} (#{base_path}) for crawling")
    Resque.enqueue(Worker::AnalyzePath, id, nil, '/')
  end
  
  def to_s
    name
  end
end
