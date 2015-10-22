# Add authorization strategy to grape and replace default http_basic
Grape::Middleware::Auth::Strategies.add(:http_basic, Nucleus::API::Middleware::BasicAuth,
                                        ->(options) { [options[:realm]] })
