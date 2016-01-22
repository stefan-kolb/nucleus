# [optional] The available levels are: FATAL, ERROR, WARN, INFO, DEBUG
# Defaults to: Logger::Severity::WARN
# nucleus_config.logging.level = Logger::Severity::WARN

# [optional] Logging directory
# Defaults to: File.expand_path(File.join(File.dirname(__FILE__), '..', 'log'))
# nucleus_config.logging.path = File.expand_path(File.join(File.dirname(__FILE__), '..', 'log'))

# [optional] Options to start the backend.
# See http://www.rubydoc.info/gems/moneta/Moneta/Adapters for valid options on the chosen adapter.
# Defaults to: {}
# nucleus_config.db.backend_options = {}

# [optional] Please specify the DB directory if you plan to use a file storage.
# Defaults to: a temporary directory.
# nucleus_config.db.path = '/Users/cmr/Documents/workspace-rubymine/nucleus/store/'

# [optional] If true, the DB will be deleted when the server is being closed.
# Defaults to: true
# nucleus_config.db.delete_on_shutdown = false

# [optional, requires 'nucleus_config.db.path'] If true, the DB will be initialized with default values,
# which may partially override previously persisted entities.
# False keeps the changes that were applied during runtime.
# Defaults to: false
# nucleus_config.db.override = false

# [optional] Specify the location of a private key (ssh-rsa, OpenSSH) that shall be used for Git actions.
# E.g. /home/myusername/.ssh/id_rsa
# If set to false, Nucleus will use its own private key (config/nucleus_git_key.pem) to authenticate all Git actions.
# Defaults to: nil
# nucleus_config.ssh.custom_key = nil

# [optional] Specify the public API description
# nucleus_config.api.title = 'Nucleus - Platform as a Service abstraction layer API'
# nucleus_config.api.description = 'Nucleus allows to manage multiple PaaS providers with just one API to be used'
# nucleus_config.api.contact = 'stefan.kolb@uni-bamberg.de'
# # The name of the license.
# nucleus_config.api.license = 'TBD'
# # The URL of the license.
# nucleus_config.api.license_url = ''
# # The URL of the API terms and conditions.
# nucleus_config.api.terms_of_service_url = 'API still under development, no guarantees (!)'
