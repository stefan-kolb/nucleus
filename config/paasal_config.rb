# [optional] The available levels are: FATAL, ERROR, WARN, INFO, DEBUG
# Defaults to: Logger::Severity::WARN
# paasal_config.logging.level = Logger::Severity::WARN

# [optional] Logging directory
# Defaults to: File.expand_path(File.join(File.dirname(__FILE__), '..', 'log'))
# paasal_config.logging.path = File.expand_path(File.join(File.dirname(__FILE__), '..', 'log'))

# [optional] Database backend to use. Choose one of: [:Daybreak, :LMDB]
# Defaults to: :Daybreak on Unix, :LMDB on windows systems.
# paasal_config.db.backend = :Daybreak

# [optional] Options to start the backend.
# See http://www.rubydoc.info/gems/moneta/Moneta/Adapters for valid options on the chosen adapter.
# Defaults to: {}
# paasal_config.db.backend_options = {}

# [optional] Please specify the DB directory if you plan to use a file storage.
# Defaults to: a temporary directory.
# paasal_config.db.path = '/Users/cmr/Documents/workspace-rubymine/paasal/store/'

# [optional] If true, the DB will be deleted when the server is being closed.
# Defaults to: true
# paasal_config.db.delete_on_shutdown = false

# [optional, requires 'paasal_config.db.path'] If true, the DB will be initialized with default values,
# which may partially override previously persisted entities.
# False keeps the changes that were applied during runtime.
# Defaults to: false
# paasal_config.db.override = false

paasal_config.api.title = 'PaaSal - Platform as a Service abstraction layer API'
paasal_config.api.description = 'PaaSal allows to manage multiple PaaS providers with just one API to be used'
paasal_config.api.contact = 'cedric.roeck@gmail.com'
# The name of the license.
paasal_config.api.license = ''
# The URL of the license.
paasal_config.api.license_url = ''
# The URL of the API terms and conditions.
paasal_config.api.terms_of_service_url = 'API still under development, no guarantees (!)'