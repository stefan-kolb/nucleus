module Nucleus
  # The {ErrorMessages} module groups all error definitions that can be returned by the RESTful API.
  # With its constants, it provides the skeleton to create error messages that comply with the error schema of Nucleus.
  module ErrorMessages
    #################
    # CLIENT ERRORS #
    #################

    ENDPOINT_BAD_REQUEST = {
      status: 400,
      error_code: 400_001,
      message: 'Bad Request'
    }.freeze

    AUTH_BAD_REQUEST = {
      status: 400,
      error_code: 400_002,
      message: 'Bad Authentication Request'
    }.freeze

    BAD_REQUEST_VALIDATION = {
      status: 400,
      error_code: 400_003,
      message: 'Bad Request: Parameter validation failed'
    }.freeze

    BAD_REQUEST_APP_ARCHIVE = {
      status: 400,
      error_code: 400_004,
      message: 'Bad Request: Application archive is damaged or did not match the declared file format'
    }.freeze

    AUTH_UNAUTHORIZED = {
      status: 401,
      error_code: 401_000,
      message: 'Unauthorized: Authentication failed'
    }.freeze

    ENDPOINT_AUTH_FAILED = {
      status: 401,
      error_code: 401_001,
      message: 'Authentication failed, endpoint rejected authentication attempt'
    }.freeze

    NOT_FOUND = {
      status: 404,
      error_code: 404_000,
      message: 'The resource could not be found'
    }.freeze

    ENDPOINT_NOT_FOUND = {
      status: 404,
      error_code: 404_001,
      message: 'The resource could not be found'
    }.freeze

    INVALID_ACCEPT_HEADER = {
      status: 406,
      error_code: 406_000,
      message: 'Invalid Accept header, vendor or version not found'
    }.freeze

    BAD_REQUEST_ENTITY = {
      status: 422,
      error_code: 422_000,
      message: 'Unprocessable Entity: Request was valid, but has been rejected by the endpoint, '\
      'saying the message was semantically false. Check the dev_message for detailed error analysis'
    }.freeze

    # All platform specific semantic errors should have a unique error code!
    PLATFORM_SPECIFIC_ERROR_ENTITY = {
      status: 422,
      error_code: 422_001,
      message: 'Unprocessable Entity: Request format was valid, but has been rejected by the endpoint, '\
        'saying the message contains data that can not be processed by this specific platform.'
    }.freeze

    # Quota violations are a common issue and therefore deserve their own message ;)
    PLATFORM_QUOTA_ERROR = {
      status: 422,
      error_code: 422_002,
      message: 'Unprocessable Entity: Request format was valid, but has been rejected by the endpoint. '\
        'Your account would exceed its quota limits. Please check your account and its billing status.'
    }.freeze

    #################
    # SERVER ERRORS #
    #################

    RESCUED = {
      status: 500,
      error_code: 500_000,
      message: 'Oops, something went terribly wrong here :/'
    }.freeze

    RESCUED_ADAPTER_CALL = {
      status: 500,
      error_code: 500_001,
      message: 'Endpoint call failed with unforeseen cause'
    }.freeze

    RESCUED_ADAPTER_CALL_SERVER = {
      status: 500,
      error_code: 500_002,
      message: 'Endpoint crashed with server error'
    }.freeze

    MISSING_IMPLEMENTATION = {
      status: 501,
      error_code: 501_000,
      message: 'Not Implemented'
    }.freeze

    UNAVAILABLE = {
      status: 503,
      error_code: 503_000,
      message: 'Service Unavailable'
    }.freeze

    PLATFORM_GATEWAY_TIMEOUT = {
      status: 504,
      error_code: 504_000,
      message: 'Gateway Timeout. The platform raised an internal Timeout error. We don\'t know to what '\
        'degree the request has been processed, or if it wasn\'t executed at all.'
    }.freeze
  end
end
