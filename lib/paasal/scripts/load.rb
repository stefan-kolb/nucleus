# First, load 3rd party dependencies
require_relative 'load_dependencies'

# require all patched classes
require_rel '../ext'

# OS detection
require 'paasal/os'

# Root directory convenience module
require 'paasal/root_dir'

# core
require_rel '../core'

# adapters
require_rel '../adapters'
