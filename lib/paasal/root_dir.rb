module Nucleus
  # Return the project's root directory.
  # @return [Path] project's root directory
  def self.root
    File.join(__dir__, '..', '..')
  end

  # Return the project's main source code directory 'lib/nucleus''.
  # @return [Path] project's main source code directory
  def self.src
    File.join(Nucleus.root, '/lib/paasal')
  end
end
