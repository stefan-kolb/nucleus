module Paasal
  # Return the project's root directory.
  # @return [Path] project's root directory
  def self.root
    File.expand_path(File.dirname(__FILE__) + '/..')
  end
end
