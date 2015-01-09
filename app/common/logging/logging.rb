module Paasal
  module Logging
    def logger
      return @logger if @logger
      # prepare logging dir
      root = ::File.expand_path("../../../../", __FILE__)
      logDir = ::File.join(root,'log')
      FileUtils.mkdir_p(logDir) unless File.directory?(logDir)
      # create the loggers
      stdLog = Logger.new(STDOUT)
      fileLog = Logger.new(::File.join(root,'log','paasal.log'))
      # apply the log level from the app. configuration
      @logger = MultiLogger.new(:level => configatron.logging.level, :loggers => [stdLog, fileLog])
      @logger
    end
  end
end