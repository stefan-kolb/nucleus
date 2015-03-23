# Operating System module to detect the current platform
# From: http://stackoverflow.com/questions/170956/how-can-i-find-which-operating-system-my-ruby-program-is-running-on
module OS
  # Is the current platform windows?
  # @return [Boolean] true if on windows, else false
  def self.windows?
    (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil
  end

  # Is the current platform OS X?
  # @return [Boolean] true if on a mac, else false
  def self.mac?
    (/darwin/ =~ RUBY_PLATFORM) != nil
  end

  # Is the current platform Unix?
  # @return [Boolean] true if on Unix, else false
  def self.unix?
    !OS.windows?
  end

  # Is the current platform Linux?
  # @return [Boolean] true if on Linux, else false
  def self.linux?
    OS.unix? && !OS.mac?
  end
end
