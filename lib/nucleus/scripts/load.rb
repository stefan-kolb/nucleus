# First, load 3rd party dependencies
require_relative 'load_dependencies'

# require all patched classes
require_rel '../ext'

# OS detection
require 'nucleus/os'

# Root directory convenience module
require 'nucleus/root_dir'

# core
require_rel '../core'

# adapters
require_rel '../adapters'
