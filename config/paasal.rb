# [optional] The available levels are: FATAL, ERROR, WARN, INFO, DEBUG
# Defaults to: Logger::Severity::WARN
configatron.logging.level = Logger::Severity::DEBUG

# [optional] Logging directory
# Defaults to: File.expand_path(File.join(File.dirname(__FILE__), '..', 'log'))
# configatron.logging.path = File.expand_path(File.join(File.dirname(__FILE__), '..', 'log'))

# [optional] Database backend to use. Choose one of: [:Daybreak, :LMDB]
# Defaults to: :Daybreak on Unix, :LMDB on windows systems.
# configatron.db.backend = :Daybreak

# [optional] Options to start the backend.
# See http://www.rubydoc.info/gems/moneta/Moneta/Adapters for valid options on the chosen adapter.
# Defaults to: {}
# configatron.db.backend_options = {}

# [optional] Please specify the DB directory if you plan to use a file storage.
# Defaults to: a temporary directory.
configatron.db.path = '/Users/cmr/Documents/workspace-rubymine/paasal/store/'

# [optional] If true, the DB will be deleted when the server is being closed.
# Defaults to: false
configatron.db.delete_on_shutdown = true

# [optional, requires 'configatron.db.path'] If true, the DB will be initialized with default values,
# which may partially override previously persisted entities.
# False keeps the changes that were applied during runtime.
# Defaults to: false
configatron.db.override = false

configatron.api.title = 'PaaSal - Platform as a Service abstraction layer API'
configatron.api.description = 'PaaSal allows to manage multiple PaaS providers with just one API to be used'
configatron.api.contact = 'cedric.roeck@gmail.com'
# The name of the license.
configatron.api.license = ''
# The URL of the license.
configatron.api.license_url = ''
# The URL of the API terms and conditions.
configatron.api.terms_of_service_url = 'API still under development, no guarantees (!)'
