module Paasal
  module Adapters
    module V1
      # Stub adapter for PaaSal API version 1.<br>
      # The stub provides all methods that an actual adapter should implement.<br>
      # It also contains the documentation that describes the expected method behaviour,
      # which must be matched by the adapters.<br>
      # <br>
      # Adapter methods shall raise:<br>
      # {Errors::AdapterResourceNotFoundError} == 404 if a resource could not be found<br>
      # {Errors::SemanticAdapterRequestError} == 422 if the request could not be processed due to
      # common semantic errors<br>
      # {Errors::PlatformSpecificSemanticError} == 422 if the request could not be processed due to
      # semantic errors that are specific to the endpoint / platform, for instance quota restrictions.<br>
      # {Errors::UnknownAdapterCallError} == 500 if the endpoint API shows unexpected behavior,
      # not matching the implementation<br>
      # {Errors::AdapterMissingImplementationError} == 501 if a feature is not (yet) implemented by the adapter<br>
      class Stub < BaseAdapter
        ERROR_MSG = 'Adapter is missing an implementation to support this feature'

        # TODO: add documentation
        def authenticate(username, password)
          fail Errors::AdapterMissingImplementationError, ERROR_MSG
        end

        # Return a list of all {Paasal::API::Models::Region class} compatible objects
        # that are available on the current endpoint.<br>
        # If the platform does not offer multi-region support, one 'default' region shall be returned.
        # @return [Array<Hash>] available regions on the endpoint
        def regions
          fail Errors::AdapterMissingImplementationError, ERROR_MSG
        end

        # Return the {Paasal::API::Models::Region class} compatible information
        # regarding the region with the given region_id.
        #
        # @param [String] region_id Id if the region object to retrieve
        # @raise [Paasal::Errors::AdapterResourceNotFoundError] if no region matching the region_id could be found
        # @return [Hash] region with the id region_id
        def region(region_id)
          fail Errors::AdapterMissingImplementationError, ERROR_MSG
        end

        # TODO: add documentation
        def applications
          fail Errors::AdapterMissingImplementationError, ERROR_MSG
        end

        # TODO: add documentation
        def application(_entity_id)
          fail Errors::AdapterMissingImplementationError, ERROR_MSG
        end

        # TODO: add documentation
        def create_application(_entity_hash)
          fail Errors::AdapterMissingImplementationError, ERROR_MSG
        end

        # TODO: add documentation
        def update_application(_entity_id, _entity_hash)
          fail Errors::AdapterMissingImplementationError, ERROR_MSG
        end

        # TODO: add documentation
        def delete_application(entity_id)
          fail Errors::AdapterMissingImplementationError, ERROR_MSG
        end

        # TODO: add documentation
        def domains(application_id)
          fail Errors::AdapterMissingImplementationError, ERROR_MSG
        end

        # TODO: add documentation
        def domain(application_id, entity_id)
          fail Errors::AdapterMissingImplementationError, ERROR_MSG
        end

        # TODO: add documentation
        def create_domain(application_id, entity_hash)
          fail Errors::AdapterMissingImplementationError, ERROR_MSG
        end

        # TODO: add documentation
        def delete_domain(application_id, entity_id)
          fail Errors::AdapterMissingImplementationError, ERROR_MSG
        end

        # TODO: add documentation
        def env_vars(application_id)
          fail Errors::AdapterMissingImplementationError, ERROR_MSG
        end

        # TODO: add documentation
        def env_var(application_id, entity_id)
          fail Errors::AdapterMissingImplementationError, ERROR_MSG
        end

        # TODO: add documentation
        def create_env_var(application_id, env_var)
          fail Errors::AdapterMissingImplementationError, ERROR_MSG
        end

        # TODO: add documentation
        def update_env_var(application_id, env_var_id, env_var)
          fail Errors::AdapterMissingImplementationError, ERROR_MSG
        end

        # TODO: add documentation
        def delete_env_var(application_id, entity_id)
          fail Errors::AdapterMissingImplementationError, ERROR_MSG
        end

        # TODO: add documentation
        def start(application_id)
          fail Errors::AdapterMissingImplementationError, ERROR_MSG
        end

        # TODO: add documentation
        def stop(application_id)
          fail Errors::AdapterMissingImplementationError, ERROR_MSG
        end

        # TODO: add documentation
        def restart(application_id)
          fail Errors::AdapterMissingImplementationError, ERROR_MSG
        end

        # TODO: add documentation
        def deploy(application_id, application_archive, compression_format)
          fail Errors::AdapterMissingImplementationError, ERROR_MSG
        end

        # TODO: add documentation
        def rebuild(application_id)
          fail Errors::AdapterMissingImplementationError, ERROR_MSG
        end

        # TODO: add documentation
        def download(application_id, compression_format)
          fail Errors::AdapterMissingImplementationError, ERROR_MSG
        end

        # TODO: add documentation
        def scale(application_id, instances)
          fail Errors::AdapterMissingImplementationError, ERROR_MSG
        end

        # TODO: add documentation
        def log?(application_id, log_id)
          fail Errors::AdapterMissingImplementationError, ERROR_MSG
        end

        # TODO: add documentation
        def logs(application_id)
          fail Errors::AdapterMissingImplementationError, ERROR_MSG
        end

        # TODO: add documentation
        def log_entries(application_id, log_id)
          fail Errors::AdapterMissingImplementationError, ERROR_MSG
        end

        # TODO: add documentation
        def tail(application_id, log_id, stream)
          fail Errors::AdapterMissingImplementationError, ERROR_MSG
        end
      end
    end
  end
end
