class BatchWorker

  def self.run_all(config = {})
    workers = self.workers(config)
    logger.info "Applying decay to #{workers.join(', ')}"

    self::MAX_RUNS.times do
      break if workers.empty?
      workers = workers.select do |worker|
        worker.run
      end
    end

    unless workers.empty?
      logger.warn "Some workers did not finish their work, even after #{self::MAX_RUNS} runs: #{workers.join(', ')}"
    end
  end

protected

  def self.logger
    Rails.logger.info
  end

  def logger
    self.class.logger
  end

end
