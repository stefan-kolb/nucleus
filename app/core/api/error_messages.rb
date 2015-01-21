module Paasal
  module API
    module ErrorMessages

      RESCUED = {
          message: 'Oops, something went wrong here :/',
          status: 500,
          error_code: 500
      }

      NOT_FOUND = {
        message: 'The resource could not be found',
        status: 404,
        error_code: 404
      }

      AUTH_UNAUTHORIZED = {
          message: 'Unauthorized: Authentication failed',
          status: 401,
          error_code: 401
      }

      BAD_REQUEST = {
          message: 'Bad Request: Parameter validation failed',
          status: 400,
          error_code: 4000
      }

      AUTH_BAD_REQUEST = {
          message: 'Bad Authentication Request',
          status: 400,
          error_code: 4001
      }

    end
  end
end