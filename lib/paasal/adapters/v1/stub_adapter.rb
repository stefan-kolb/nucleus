module Paasal
  module Adapters
    # Version 1, or the first release of the PaaSal API.<br>
    # It provides basic management functionality to handle:<br>
    # * applications
    # * domains
    # * environment variables
    # * logging
    # * deployment
    # * scaling (horizontal and vertical)
    module V1
      # Stub adapter for PaaSal API version 1.<br>
      # The stub provides all methods that an actual adapter should implement.<br>
      # It also contains the documentation that describes the expected method behaviour,
      # which must be matched by the adapters.<br>
      # <br>
      # Adapter methods shall raise:<br>
      # {Errors::AuthenticationError} == 401 if a endpoint call failed due to bad credentials<br>
      # {Errors::AdapterResourceNotFoundError} == 404 if a resource could not be found<br>
      # {Errors::SemanticAdapterRequestError} == 422 if the request could not be processed due to
      # common semantic errors<br>
      # {Errors::PlatformSpecificSemanticError} == 422 if the request could not be processed due to
      # semantic errors that are specific to the endpoint / platform, for instance quota restrictions.<br>
      # {Errors::UnknownAdapterCallError} == 500 if the endpoint API shows unexpected behavior,
      # not matching the implementation<br>
      # {Errors::AdapterMissingImplementationError} == 501 if a feature is not (yet) implemented by the adapter<br>
      #
      # If embedded in the Grape Restful API, authentication errors and bad requests are handled by Grape.<br>
      # If an adapter is used within the +gem+, the developer must take care of authentication handling and
      # missing form data.
      #
      # @abstract
      class Stub < BaseAdapter
        # Error message saying that the adapter feature has not been implemented yet.
        NOT_IMPLEMENTED_ERROR = Errors::AdapterMissingImplementationError.new(
          'Adapter is missing an implementation to support this feature')

        # Build an Authentication client that can handle the authentication to the endpoint
        # given the username and a matching password.
        # @return [Paasal::Adapters::AuthClient] authentication client
        def auth_client
          fail NOT_IMPLEMENTED_ERROR
        end

        # Return a list of all {Paasal::API::Models::Region class} compatible objects
        # that are available on the current endpoint.<br>
        # If the platform does not offer multi-region support, one 'default' region shall be returned.
        # @raise [Paasal::Errors::AuthenticationError] if the authentication on the endpoint failed
        # @return [Hash, Paasal::API::Models::Regions] region entity compatible Hash of available regions
        def regions
          fail NOT_IMPLEMENTED_ERROR
        end

        # Return the {Paasal::API::Models::Region class} compatible information
        # regarding the region with the given region_id.
        #
        # @param [String] region_id Id of the region object to retrieve
        # @raise [Paasal::Errors::AdapterResourceNotFoundError] if no region matching the region_id could be found
        # @raise [Paasal::Errors::AuthenticationError] if the authentication on the endpoint failed
        # @return [Hash, Paasal::API::Models::Region] region entity compatible Hash with the id region_id
        def region(region_id)
          fail NOT_IMPLEMENTED_ERROR
        end

        # Get a list of all applications that are accessible to the authenticated user account.
        # @raise [Paasal::Errors::AuthenticationError] if the authentication on the endpoint failed
        # @return [Hash, Paasal::API::Models::Applications] application entity list compatible hash
        def applications
          fail NOT_IMPLEMENTED_ERROR
        end

        # Retrieve the application entity of the application with the given application_id.
        # @param [String] application_id Id of the application object to retrieve
        # @raise [Paasal::Errors::AdapterResourceNotFoundError] if no app matching the application_id could be found
        # @raise [Paasal::Errors::AuthenticationError] if the authentication on the endpoint failed
        # @return [Hash, Paasal::API::Models::Application] application entity compatible Hash with the application_id
        def application(application_id)
          fail NOT_IMPLEMENTED_ERROR
        end

        # Create a new application on the endpoint using the given application entity.
        # @param [Hash, Paasal::API::Models::Application] application entity compatible Hash.
        # @option application [String] :name The name of the application
        # @option application [Array<String>] :runtimes Runtimes (buildpacks) to use with the application
        # @option application [String] :region Region where the application shall be deployed,
        #   call {#regions} for a list of allowed values
        # @option application [Boolean] :autoscaled True if the application shall scale automatically,
        #   false if manual scaling shall be used. WARNING: This option is currently not supported by most vendors!
        # @raise [Paasal::Errors::AuthenticationError] if the authentication on the endpoint failed
        # @return [Hash, Paasal::API::Models::Application] application entity compatible Hash
        #   of the created application
        def create_application(application)
          fail NOT_IMPLEMENTED_ERROR
        end

        # Update an application on the endpoint using the given application entity.
        # @param [Hash, Paasal::API::Models::Application] application application entity compatible Hash.
        # @option application [String] :name The updated name of the application
        # @option application [Array<String>] :runtimes Runtimes (buildpacks) to use with the application
        # @param [String] application_id Id of the application object that shall be updated
        # @raise [Paasal::Errors::AdapterResourceNotFoundError] if no app matching the application_id could be found
        # @raise [Paasal::Errors::AuthenticationError] if the authentication on the endpoint failed
        # @return [Hash, Paasal::API::Models::Application] application entity compatible Hash with the application_id
        def update_application(application_id, application)
          fail NOT_IMPLEMENTED_ERROR
        end

        # Delete the application with the given application_id on the endpoint.
        # @param [String] application_id Id of the application object that shall be deleted
        # @raise [Paasal::Errors::AdapterResourceNotFoundError] if no app matching the application_id could be found
        # @raise [Paasal::Errors::AuthenticationError] if the authentication on the endpoint failed
        # @return [void]
        def delete_application(application_id)
          fail NOT_IMPLEMENTED_ERROR
        end

        # Get a list of all domains that are assigned to the application.
        # @param [String] application_id Id of the application for which the domains are to be retrieved
        # @raise [Paasal::Errors::AdapterResourceNotFoundError] if no app matching the application_id could be found
        # @raise [Paasal::Errors::AuthenticationError] if the authentication on the endpoint failed
        # @return [Hash, Paasal::API::Models::Domains] domain entity list compatible hash
        def domains(application_id)
          fail NOT_IMPLEMENTED_ERROR
        end

        # Retrieve the domain entity of the application with the given application_id and the domain with the domain_id.
        # @param [String] application_id Id of the application for which the domain is to be retrieved
        # @param [String] domain_id Id of the domain object to retrieve
        # @raise [Paasal::Errors::AdapterResourceNotFoundError] if no app matching the application_id,
        #   or no domain matching the domain_id could be found
        # @raise [Paasal::Errors::AuthenticationError] if the authentication on the endpoint failed
        # @return [Hash, Paasal::API::Models::Domain] domain entity compatible hash of the domain with the domain_id
        def domain(application_id, domain_id)
          fail NOT_IMPLEMENTED_ERROR
        end

        # Create a new domain using the given domain entity and assign it to the application.
        # @param [String] application_id Id of the application for which the domain is to be created
        # @param [Hash, Paasal::API::Models::Domain] domain domain entity compatible Hash.
        # @option application [String] :name The domain name, e.g. +myapplication.example.org+
        # @raise [Paasal::Errors::AdapterResourceNotFoundError] if no app matching the application_id,
        #   or no domain matching the domain_id could be found
        # @raise [Paasal::Errors::AuthenticationError] if the authentication on the endpoint failed
        # @return [Hash, Paasal::API::Models::Domain] domain entity compatible hash of the created domain
        def create_domain(application_id, domain)
          fail NOT_IMPLEMENTED_ERROR
        end

        # Delete the domain of the application with the domain_id.
        # @param [String] application_id Id of the application for which the domain is to be deleted
        # @param [String] domain_id Id of the domain object to delete
        # @raise [Paasal::Errors::AdapterResourceNotFoundError] if no app matching the application_id,
        #   or no domain matching the domain_id could be found
        # @raise [Paasal::Errors::AuthenticationError] if the authentication on the endpoint failed
        # @return [void]
        def delete_domain(application_id, domain_id)
          fail NOT_IMPLEMENTED_ERROR
        end

        # Get a list of all environment variables that are assigned to the application.
        # @param [String] application_id Id of the application for which the env_vars are to be retrieved
        # @raise [Paasal::Errors::AdapterResourceNotFoundError] if no app matching the application_id could be found
        # @raise [Paasal::Errors::AuthenticationError] if the authentication on the endpoint failed
        # @return [Hash, Paasal::API::Models::EnvironmentVariables] environment variable entity list compatible hash
        def env_vars(application_id)
          fail NOT_IMPLEMENTED_ERROR
        end

        # Retrieve the environment variable entity of the application with the given application_id and the env. var
        # with the env_var_id.
        # @param [String] application_id Id of the application for which the env_var is to be retrieved
        # @param [String] env_var_id Id of the env_var object to retrieve
        # @raise [Paasal::Errors::AdapterResourceNotFoundError] if no app matching the application_id,
        #   or no environment variable matching the env_var_id could be found
        # @raise [Paasal::Errors::AuthenticationError] if the authentication on the endpoint failed
        # @return [Hash, Paasal::API::Models::EnvironmentVariable] environment variable entity compatible hash
        #   of the env. var with the env_var_id
        def env_var(application_id, env_var_id)
          fail NOT_IMPLEMENTED_ERROR
        end

        # Create a new environment variable using the given env. var entity and assign it to the application.
        # @param [String] application_id Id of the application for which the env_var is to be created
        # @param [Hash, Paasal::API::Models::EnvironmentVariable] env_var env. var entity compatible Hash.
        # @option env_var [String] :key Key of the environment variable, e.g. +IP+
        # @option env_var [String] :value Value of the environment variable, e.g. +0.0.0.0+
        # @raise [Paasal::Errors::AdapterResourceNotFoundError] if no app matching the application_id could be found
        # @raise [Paasal::Errors::AuthenticationError] if the authentication on the endpoint failed
        # @return [Hash, Paasal::API::Models::EnvironmentVariable] environment variable entity compatible hash
        #   of the created env. var
        def create_env_var(application_id, env_var)
          fail NOT_IMPLEMENTED_ERROR
        end

        # Update the environment variable of the application, using the given env. var entity.
        # @param [String] application_id Id of the application for which the env_var is to be updated
        # @param [String] env_var_id Id of the env_var object to update
        # @param [Hash, Paasal::API::Models::EnvironmentVariable] env_var env. var entity compatible Hash.
        # @option env_var [String] :value Value of the environment variable, e.g. +0.0.0.0+
        # @raise [Paasal::Errors::AdapterResourceNotFoundError] if no app matching the application_id,
        #   or no environment variable matching the env_var_id could be found
        # @raise [Paasal::Errors::AuthenticationError] if the authentication on the endpoint failed
        # @return [Hash, Paasal::API::Models::EnvironmentVariable] environment variable entity compatible hash
        #   of the updated env. var
        def update_env_var(application_id, env_var_id, env_var)
          fail NOT_IMPLEMENTED_ERROR
        end

        # Delete the environment variable of the application with the env_var_id.
        # @param [String] application_id Id of the application for which the env_var is to be deleted
        # @param [String] env_var_id Id of the env_var object to delete
        # @raise [Paasal::Errors::AdapterResourceNotFoundError] if no app matching the application_id,
        #   or no environment variable matching the env_var_id could be found
        # @raise [Paasal::Errors::AuthenticationError] if the authentication on the endpoint failed
        # @return [void]
        def delete_env_var(application_id, env_var_id)
          fail NOT_IMPLEMENTED_ERROR
        end

        # Start all instances of the application with the application_id.
        # The state of all application instances should become +running+ when all actions are finished
        # (unless there are technical errors preventing the application to start).
        # Preconditions:<br>
        # * application must have been deployed
        # Postconditions (delayed):<br>
        # * state == running
        # @param [String] application_id Id of the application which is to be started
        # @raise [Paasal::Errors::AdapterResourceNotFoundError] if the application could not be found
        # @raise [Paasal::Errors::AuthenticationError] if the authentication on the endpoint failed
        # @raise [Paasal::Errors::SemanticAdapterRequestError] if the application is not deployed
        # @return [Hash, Paasal::API::Models::Application] application entity compatible Hash
        def start(application_id)
          fail NOT_IMPLEMENTED_ERROR
        end

        # Stop all instances of the application with the application_id.
        # The state of all application instances will become +stopped+ when all actions are finished.
        # Preconditions:<br>
        # * application must have been deployed
        # Postconditions (delayed):<br>
        # * state == stopped
        # @param [String] application_id Id of the application which is to be stopped
        # @raise [Paasal::Errors::AdapterResourceNotFoundError] if the application could not be found
        # @raise [Paasal::Errors::AuthenticationError] if the authentication on the endpoint failed
        # @raise [Paasal::Errors::SemanticAdapterRequestError] if the application is not deployed
        # @return [Hash, Paasal::API::Models::Application] application entity compatible Hash
        def stop(application_id)
          fail NOT_IMPLEMENTED_ERROR
        end

        # Restart all instances of the application with the application_id.
        # The state of all application instances should become +running+ when all actions are finished
        # (unless there are technical errors preventing the application to start).
        # Preconditions:<br>
        # * application must have been deployed
        # Postconditions (delayed):<br>
        # * state == running
        # @param [String] application_id Id of the application which is to be restarted
        # @raise [Paasal::Errors::AdapterResourceNotFoundError] if the application could not be found
        # @raise [Paasal::Errors::AuthenticationError] if the authentication on the endpoint failed
        # @raise [Paasal::Errors::SemanticAdapterRequestError] if the application is not deployed
        # @return [Hash, Paasal::API::Models::Application] application entity compatible Hash
        def restart(application_id)
          fail NOT_IMPLEMENTED_ERROR
        end

        # Deploy the data of the application given the compressed application archive.<br>
        # The application shall not be running when the deployment is finished.
        # Postconditions (delayed):<br>
        # * state == deployed
        # @param [String] application_id Id of the application for which the data is to be deployed
        # @param [Tempfile] application_archive compressed application archive that shall be deployed
        # @param [Symbol] compression_format archive formats, see {Paasal::API::Enums::CompressionFormats.all}
        #   for a list of all allowed values
        # @raise [Paasal::Errors::AdapterResourceNotFoundError] if the application could not be found
        # @raise [Paasal::Errors::AuthenticationError] if the authentication on the endpoint failed
        # @raise [Paasal::Errors::AdapterRequestError] if the application archive that shall be deployed is no
        #   valid application archive, or if the application_archive / compression_format are not supported
        # @return [void]
        def deploy(application_id, application_archive, compression_format)
          fail NOT_IMPLEMENTED_ERROR
        end

        # Rebuild the recently deployed bits of the application.<br>
        # The rebuild can be used to update the application to use a new version of the underlying runtime or fix a
        # previously failed application start after the issues have been resolved.
        # @param [String] application_id Id of the application which is to be rebuild
        # @raise [Paasal::Errors::AdapterResourceNotFoundError] if the application could not be found
        # @raise [Paasal::Errors::AuthenticationError] if the authentication on the endpoint failed
        # @return [Hash, Paasal::API::Models::Application] application entity compatible Hash
        def rebuild(application_id)
          fail NOT_IMPLEMENTED_ERROR
        end

        # Download the application data that is currently deployed on the platform.
        # The downloaded application archive must contain at least all files that were originally deployed,
        # but can also contain additional files, for instance log files.
        # @param [String] application_id Id of the application of which the data is to be downloaded
        # @param [Symbol] compression_format archive formats, see {Paasal::API::Parameters::Enums.all}
        #   for a list of all allowed values
        # @raise [Paasal::Errors::AdapterResourceNotFoundError] if the application could not be found
        # @raise [Paasal::Errors::AuthenticationError] if the authentication on the endpoint failed
        # @raise [Paasal::Errors::AdapterRequestError] if the application archive that shall be deployed is no
        #   valid application archive, or if the compression_format is not supported
        # @return [StringIO] binary application data
        def download(application_id, compression_format)
          fail NOT_IMPLEMENTED_ERROR
        end

        # TODO: Finish documentation when vertical scaling is added
        # Scale the application and adjust the number of instances that shall be running.
        # @param [String] application_id Id of the application which is to be scaled
        # @raise [Paasal::Errors::AdapterResourceNotFoundError] if the application could not be found
        # @raise [Paasal::Errors::AuthenticationError] if the authentication on the endpoint failed
        # @raise [Paasal::Errors::SemanticAdapterRequestError] if the number of instances is disallowed on the platform
        # @return [Hash, Paasal::API::Models::Application] application entity compatible Hash
        def scale(application_id, instances)
          fail NOT_IMPLEMENTED_ERROR
        end

        # Assert whether the given log_id is valid for the application_id.
        # @param [String] application_id Id of the application of which the log existence is to be checked
        # @param [String] log_id Id of the log whose existence is to be checked
        # @raise [Paasal::Errors::AdapterResourceNotFoundError] if the application could not be found
        # @raise [Paasal::Errors::AuthenticationError] if the authentication on the endpoint failed
        # @return [Boolean] returns true if there is a log for the application with the log_id,
        #   false if it does not exist
        def log?(application_id, log_id)
          fail NOT_IMPLEMENTED_ERROR
        end

        # Get a list of all logs that are available for the application.
        # @param [String] application_id Id of the application of which the logs are to be listed
        # @raise [Paasal::Errors::AdapterResourceNotFoundError] if the application could not be found
        # @raise [Paasal::Errors::AuthenticationError] if the authentication on the endpoint failed
        # @return [Hash, Paasal::API::Models::Logs] log entity list compatible hash
        def logs(application_id)
          fail NOT_IMPLEMENTED_ERROR
        end

        # Retrieve all log entries of the log.
        # @param [String] application_id Id of the application of which the log_entries are to be retrieved
        # @param [String] log_id Id of the log for which the entries are to be retrieved
        # @raise [Paasal::Errors::AdapterResourceNotFoundError] if the application or log could not be found
        # @raise [Paasal::Errors::AuthenticationError] if the authentication on the endpoint failed
        # @return [Array<String>] array of log entries, starting with the earliest entry at pos [0]
        def log_entries(application_id, log_id)
          fail NOT_IMPLEMENTED_ERROR
        end

        # Tail the logfile of the application and send each retrieved chunk, which can be a line of a file,
        # a new chunk in a received http message, or a websocket message, to the stream. The deferred tailing
        # process shall be stoppable when the +stop+ method of the returned {Paasal::Adapters::TailStopper TailStopper}
        # is called.
        # @param [String] application_id Id of the application of which the log is to be tailed
        # @param [String] log_id Id of the log that is to be tailed
        # @param [Paasal::RackStreamCallback] stream stream callback to which messages can be sent via
        #   the +send_message+ method
        # @raise [Paasal::Errors::AdapterResourceNotFoundError] if the application or log could not be found
        # @raise [Paasal::Errors::AuthenticationError] if the authentication on the endpoint failed
        # @return [Paasal::Adapters::TailStopper] callback object to stop the ongoing tail process
        def tail(application_id, log_id, stream)
          fail NOT_IMPLEMENTED_ERROR
        end

        # List all services that are available at the endpoint.
        # @raise [Paasal::Errors::AuthenticationError] if the authentication on the endpoint failed
        # @return [Hash, Paasal::API::Models::Services] services list compatible hash
        def services
          fail NOT_IMPLEMENTED_ERROR
        end

        # Retrieve the service entity matching the given service_id.
        # @param [String] service_id Id of the service that is to be retrieved
        # @raise [Paasal::Errors::AdapterResourceNotFoundError] if the service could not be found
        # @raise [Paasal::Errors::AuthenticationError] if the authentication on the endpoint failed
        # @return [Hash, Paasal::API::Models::Service] service entity compatible hash
        def service(service_id)
          fail NOT_IMPLEMENTED_ERROR
        end

        # List all plans that can be chosen for the service with the service_id, ascending order on the price.
        # @param [String] service_id Id of the service the plans belong to
        # @raise [Paasal::Errors::AdapterResourceNotFoundError] if the service could not be found
        # @raise [Paasal::Errors::AuthenticationError] if the authentication on the endpoint failed
        # @return [Hash, Paasal::API::Models::ServicePlans] service plan list compatible hash
        def service_plans(service_id)
          fail NOT_IMPLEMENTED_ERROR
        end

        # Show the plan with the plan_id that is applicable to the service with the service_id.
        # @param [String] service_id Id of the service the plans belongs to
        # @raise [Paasal::Errors::AdapterResourceNotFoundError] if the service or the plan could not be found
        # @raise [Paasal::Errors::AuthenticationError] if the authentication on the endpoint failed
        # @return [Hash, Paasal::API::Models::ServicePlan] service plan entity compatible hash
        def service_plan(service_id, plan_id)
          fail NOT_IMPLEMENTED_ERROR
        end

        # List all services that are installed on the application with the given application_id.
        # @param [String] application_id Id of the application of which the services are to be listed of
        # @raise [Paasal::Errors::AdapterResourceNotFoundError] if the application could not be found
        # @raise [Paasal::Errors::AuthenticationError] if the authentication on the endpoint failed
        # @return [Hash, Paasal::API::Models::InstalledServices] installed services list compatible hash
        def installed_services(application_id)
          fail NOT_IMPLEMENTED_ERROR
        end

        # Retrieve the installed service entity matching the given service_id that is installed
        # on the application with the given application_id.
        # @param [String] service_id Id of the installed service that is to be retrieved
        # @raise [Paasal::Errors::AdapterResourceNotFoundError] if the application or service could not be found
        # @raise [Paasal::Errors::AuthenticationError] if the authentication on the endpoint failed
        # @return [Hash, Paasal::API::Models::InstalledService] installed service entity compatible hash
        def installed_service(application_id, service_id)
          fail NOT_IMPLEMENTED_ERROR
        end

        # Add the service with the service_id to the application with the application_id.
        # @param [String] application_id Id of the application of which the service is to be added to
        # @param [Hash, Paasal::API::Models::Service] service_entity service entity compatible Hash.
        # @option env_var [String] :id ID of the service to add to the application
        # @param [Hash, Paasal::API::Models::ServicePlan] plan_entity service plan entity compatible Hash.
        # @option env_var [String] :id ID of the service plan that shall be applied
        # @raise [Paasal::Errors::AdapterResourceNotFoundError] if the application could not be found
        # @raise [Paasal::Errors::AuthenticationError] if the authentication on the endpoint failed
        # @raise [Paasal::Errors::SemanticAdapterRequestError] if the service to add or the plan to use
        #   could not be found
        # @return [Hash, Paasal::API::Models::InstalledService] installed service entity compatible hash
        def add_service(application_id, service_entity, plan_entity)
          fail NOT_IMPLEMENTED_ERROR
        end

        # Change the service, e.g. the active plan, of the service with the service_id for
        # the application with the application_id. Use the fields of the service_entity to execute the update.
        # @param [String] application_id Id of the application of which the service is to be changed
        # @param [String] service_id Id of the installed service that is to be updated. The id must not (but can) be
        #   identical to the id of the service the installed service is based on.
        # @param [Hash, Paasal::API::Models::ServicePlan] plan_entity service plan entity compatible Hash.
        # @option env_var [String] :id ID of the service plan that shall be applied
        # @raise [Paasal::Errors::AdapterResourceNotFoundError] if the application could not be found or
        #   the service was not installed on this application
        # @raise [Paasal::Errors::AuthenticationError] if the authentication on the endpoint failed
        # @raise [Paasal::Errors::SemanticAdapterRequestError] if the plan to use could not be found
        # @return [Hash, Paasal::API::Models::InstalledService] installed service entity compatible hash
        def change_service(application_id, service_id, plan_entity)
          fail NOT_IMPLEMENTED_ERROR
        end

        # Remove the installed service with the service_id from the application with the application_id.
        # @param [String] application_id Id of the application of which the service is to be removed from
        # @param [String] service_id Id of the installed service that is to be removed from the application. The id
        #   must not (but can) be identical to the id of the service the installed service is based on.
        # @raise [Paasal::Errors::AdapterResourceNotFoundError] if the application could not be found or
        #   the service was not installed on this application
        # @raise [Paasal::Errors::AuthenticationError] if the authentication on the endpoint failed
        # @return [void]
        def remove_service(application_id, service_id)
          fail NOT_IMPLEMENTED_ERROR
        end
      end
    end
  end
end
