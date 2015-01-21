module Paasal
  # Logging module for Paasal.
  # Include via
  #     include Paasal::Logging
  # and then log your messages:
  #    log.info('This is a test log message')
  #
  # @author Willem Buys
  # Idea by Willem 'Jacob' Buys, as seen on http://stackoverflow.com/questions/917566/ruby-share-logger-instance-among-module-classes
  module Logging
    def log
      @log ||= Logging.logger_for(self.class.name)
    end

    # Use a hash class-ivar to cache a unique Logger per class:
    @loggers = {}

    class << self
      def logger_for(classname)
        @loggers[classname] ||= configure_logger_for(classname)
      end

      def configure_logger_for(classname)
        # prepare logging dir
        log_dir = ::File.join('log')
        log_file = ::File.join(log_dir, 'paasal.log')
        # prepare path and create missing directories
        FileUtils.mkdir_p(log_dir) unless File.directory?(log_dir)
        # create the loggers
        std_log = Logger.new(STDOUT)
        # use rotation for x days
        file_log = Logger.new(log_file, 'daily', 7)

        # include custom log format that includes the request id
        formatter = Paasal::Logging::Formatter.new

        [file_log, std_log].each do |logger|
          # apply format
          logger.formatter = formatter
          # apply the classname
          logger.progname = classname
        end

        # apply the log level from the app. configuration
        multi_logger = MultiLogger.new(
            :level => configatron.logging.key?(:level) ? configatron.logging.level : Logger::Severity::WARN,
            :loggers => [std_log, file_log])
        multi_logger
      end
    end
  end
end
