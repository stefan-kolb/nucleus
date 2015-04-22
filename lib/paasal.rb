require 'paasal/version'

# _PaaSal_ is a RESTful abstraction layer to achieve unified deployment and management functions
# of Platform-as-a-Service (PaaS) providers.<br>
module Paasal
  # Load the default configuration
  require 'scripts/load_config'
  # Load the actual application and its dependencies
  require 'scripts/load_app'

  # now require the parts that are only relevant when using PaaSal as gem
  require 'paasal/adapter_resolver'
end
