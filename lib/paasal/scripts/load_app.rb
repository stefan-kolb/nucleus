# require all patched classes
require_rel '../ext'

# OS detection
require 'paasal/os'

# Root directory convenience module
require 'paasal/root_dir'

# core
require_rel '../core'

# persistence layer (models, stores and DAOs)
require_rel '../persistence'

# adapters
require_rel '../adapters'
