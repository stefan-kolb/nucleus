# Add authorization strategy to grape and replace default http_basic
Grape::Middleware::Auth::Strategies.add(:http_basic, Paasal::API::Middleware::BasicAuth,
                                        ->(options) { [options[:realm]] })
