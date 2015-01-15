# [optional] The available levels are: FATAL, ERROR, WARN, INFO, DEBUG
configatron.logging.level = Logger::Severity::DEBUG

# [optional] Please specify the DB directory if you plan to persist
# your vendors, providers and their endpoints
configatron.db.path = "/Users/cmr/Documents/workspace-rubymine/paasal/store/"
# [optional] If true, the DB will be deleted when the server is being closed.
configatron.db.delete_on_shutdown = true
# [optional] If true, the DB will be initialized with default values,
# which may partially override previously persisted entities
configatron.db.override = false