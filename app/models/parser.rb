class Parser
  include Mongoid::Document
  
  #
  # Priority to be used for the parser
  # Smaller numbers get called before high numbers
  #
  field :priority, :type=>Integer, :default=>100
  # 
  # Limit to only files with these mime_types.
  # This gives a hint to the analyze worker but doesn't ensure that your parser will only
  # get files of these types. You should assume that your parser may receive any kind of files
  # and ignore unknown types when it's asked to parse one.
  # If null, will accept any kind of mime type.
  #
  field :mime_types, :type => Array
  
  def parse(element)
  end

  def logger
    @@logger ||= Logger.new("#{RAILS_ROOT}/log/#{self.class.name}.log")
  end

  def self.all_for_mime_type(mime_type)
    unless mime_type
      all
    else
      any_in(
        :mime_types => mime_type.split("/").inject([]) {|a,e| a.empty? ? [e] : a << a.last + "/" + e} << nil
      )
    end
  end
end
