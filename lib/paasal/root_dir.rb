module Paasal
  # Return the project's root directory.
  # @return [Path] project's root directory
  def self.root
    File.expand_path(File.dirname(__FILE__) + '/../..')
  end

  # Return the project's main source code directory 'lib/paasal''.
  # @return [Path] project's main source code directory
  def self.src
    Paasal.root + '/lib/paasal'
  end
end
