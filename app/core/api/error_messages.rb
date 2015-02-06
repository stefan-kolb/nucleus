module Paasal
  module API
    module ErrorMessages

      #################
      # CLIENT ERRORS #
      #################

      # not further specified bad request
      BAD_REQUEST = {
          status: 400,
          error_code: 40000,
          message: 'Bad Request'
      }

      # TODO: or use 422 instead?
      ENDPOINT_BAD_REQUEST = {
          status: 400,
          error_code: 40001,
          message: 'Bad Request'
      }

      AUTH_BAD_REQUEST = {
          status: 400,
          error_code: 40002,
          message: 'Bad Authentication Request'
      }

      BAD_REQUEST_VALIDATION = {
          status: 400,
          error_code: 40003,
          message: 'Bad Request: Parameter validation failed'
      }

      AUTH_UNAUTHORIZED = {
          status: 401,
          error_code: 40100,
          message: 'Unauthorized: Authentication failed'
      }

      ENDPOINT_AUTH_FAILED = {
          status: 401,
          error_code: 40101,
          message: 'Authentication failed, endpoint rejected authentication attempt'
      }

      NOT_FOUND = {
          status: 404,
          error_code: 40400,
          message: 'The resource could not be found'
      }

      ENDPOINT_NOT_FOUND = {
          status: 404,
          error_code: 40401,
          message: 'The resource could not be found'
      }

      INVALID_ACCEPT_HEADER = {
          status: 406,
          error_code: 40600,
          message: 'Invalid Accept header, vendor or version not found'
      }

      BAD_REQUEST_ENTITY = {
          status: 422,
          error_code: 42200,
          message: 'Unprocessable Entity: Request was valid, but has been rejected by the endpoint, '\
          'saying the message was semantically false. Check the dev_message for detailed error analysis'
      }

      #################
      # SERVER ERRORS #
      #################

      RESCUED = {
        status: 500,
        error_code: 50000,
        message: 'Oops, something went wrong here :/'
      }

      RESCUED_ADAPTER_CALL = {
        status: 500,
        error_code: 50001,
        message: 'Endpoint call failed with unforeseen cause'
      }

      RESCUED_ADAPTER_CALL_SERVER = {
        status: 500,
        error_code: 50002,
        message: 'Endpoint crashed with server error'
      }
    end
  end
end
