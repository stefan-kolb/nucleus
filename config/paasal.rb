# [optional] The available levels are: FATAL, ERROR, WARN, INFO, DEBUG
configatron.logging.level = Logger::Severity::DEBUG

# [optional] Please specify the DB directory if you plan to persist
# your vendors, providers and their endpoints
configatron.db.path = '/Users/cmr/Documents/workspace-rubymine/paasal/store/'
# [optional] If true, the DB will be deleted when the server is being closed.
configatron.db.delete_on_shutdown = true
# [optional] If true, the DB will be initialized with default values,
# which may partially override previously persisted entities
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