module Paasal
  module API
    module Errors

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

    end
  end
end