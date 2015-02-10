module Paasal
  module API
    module ErrorMessages
      #################
      # CLIENT ERRORS #
      #################

      # not further specified bad request
      BAD_REQUEST = {
        status: 400,
        error_code: 400_00,
        message: 'Bad Request'
      }

      # TODO: or use 422 instead?
      ENDPOINT_BAD_REQUEST = {
        status: 400,
        error_code: 400_01,
        message: 'Bad Request'
      }

      AUTH_BAD_REQUEST = {
        status: 400,
        error_code: 400_02,
        message: 'Bad Authentication Request'
      }

      BAD_REQUEST_VALIDATION = {
        status: 400,
        error_code: 400_03,
        message: 'Bad Request: Parameter validation failed'
      }

      AUTH_UNAUTHORIZED = {
        status: 401,
        error_code: 401_00,
        message: 'Unauthorized: Authentication failed'
      }

      ENDPOINT_AUTH_FAILED = {
        status: 401,
        error_code: 401_01,
        message: 'Authentication failed, endpoint rejected authentication attempt'
      }

      NOT_FOUND = {
        status: 404,
        error_code: 404_00,
        message: 'The resource could not be found'
      }

      ENDPOINT_NOT_FOUND = {
        status: 404,
        error_code: 404_01,
        message: 'The resource could not be found'
      }

      INVALID_ACCEPT_HEADER = {
        status: 406,
        error_code: 406_00,
        message: 'Invalid Accept header, vendor or version not found'
      }

      BAD_REQUEST_ENTITY = {
        status: 422,
        error_code: 422_00,
        message: 'Unprocessable Entity: Request was valid, but has been rejected by the endpoint, '\
        'saying the message was semantically false. Check the dev_message for detailed error analysis'
      }

      #################
      # SERVER ERRORS #
      #################

      RESCUED = {
        status: 500,
        error_code: 500_00,
        message: 'Oops, something went wrong here :/'
      }

      RESCUED_ADAPTER_CALL = {
        status: 500,
        error_code: 500_01,
        message: 'Endpoint call failed with unforeseen cause'
      }

      RESCUED_ADAPTER_CALL_SERVER = {
        status: 500,
        error_code: 500_02,
        message: 'Endpoint crashed with server error'
      }
    end
  end
end
