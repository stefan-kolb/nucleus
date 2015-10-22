require 'paasal/version'

# _Nucleus_ is a RESTful abstraction layer to achieve unified deployment and management functions
# of Platform-as-a-Service (PaaS) providers.<br>
module Paasal
  # Load the default configuration
  require 'paasal/scripts/setup_config'
  # Load the actual application and its dependencies
  require 'paasal/scripts/load'

  # now require the parts that are only relevant when using Nucleus as gem
  require 'paasal/adapter_resolver'
end
