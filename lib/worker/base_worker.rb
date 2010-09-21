module Worker
  class BaseWorker

    def self.logger
      @logger ||= Logger.new("#{RAILS_ROOT}/log/worker_#{self.name}.log")
    end

  end
end
