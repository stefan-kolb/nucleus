require 'nucleus/version'

# _Nucleus_ is a RESTful abstraction layer to achieve unified deployment and management functions
# of Platform-as-a-Service (PaaS) providers.<br>
module Nucleus
  # Load the default configuration
  require 'nucleus/scripts/setup_config'
  # Load the actual application and its dependencies
  require 'nucleus/scripts/load'

  # now require the parts that are only relevant when using Nucleus as gem
  require 'nucleus/adapter_resolver'
end
