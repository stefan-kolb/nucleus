module Nucleus
  class FileExistenceError < StandardError
    def initialize(message)
      super(message)
    end
  end
end
