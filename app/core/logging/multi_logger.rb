# The MultiLogger allows to log messages not only to a file OR the stdout,
# but to both or even more loggers at the same time.
# The severity defaults to WARN but can be specified when instantiating the MultiLogger.
#
#    log_1 = Logger.new(STDOUT)
#    log_2 = Logger.new(File.open('/tmp/foo'))
#    multi_logger = MultiLogger.new(:level => Logger::WARN, :loggers => log_1)
#    multi_logger.add_logger(log_2)
#    multi_logger.warn('Something interesting happened.')
#
# By Chris Lowder, see https://gist.github.com/clowder/3639600
class MultiLogger
  attr_reader :level

  # Initialize the MultiLogger, specify the severity level for all loggers
  # and add one or more loggers.
  #
  # @param [Hash] args the options to create a message with.
  # @option args [Integer] :level (2) The severity level
  # @option args [Array<Logger>] :loggers ([]) The loggers that are initially to be added
  # @return the object
  def initialize(args = {})
    @level = args[:level] || Logger::Severity::WARN
    @loggers = []

    Array(args[:loggers]).each { |logger| add_logger(logger) }
  end

  # Add a logger to the MultiLogger and adjust its level to the MultiLogger's current level.
  #
  # @param [Logger] logger the logger to add to the MultiLogger instance
  def add_logger(logger)
    logger.level = level
    @loggers << logger
  end

  # Adjust the MultiLogger's current level.
  #
  # @param [Integer] level the severity level to apply to the MultiLogger instance
  def level=(level)
    @level = level
    @loggers.each { |logger| logger.level = level }
  end

  # Close each Logger of the MultiLogger instance
  def close
    @loggers.map(&:close)
  end

  Logger::Severity.constants.each do |level|
    define_method(level.downcase) do |*args|
      @loggers.each { |logger| logger.send(level.downcase, args) }
    end

    define_method("#{ level.downcase }?".to_sym) do
      @level <= Logger::Severity.const_get(level)
    end
  end
end
