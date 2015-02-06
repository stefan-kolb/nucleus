module Paasal
  module UrlConverter
    # Convert the URL to the secure 'HTTPS' scheme. Passed URLs must be in one of the following forms:
    #    {scheme}://{prefix.}host.domain
    #    {prefix.}host.domain
    #
    # An url that would raise an {ArgumentError} is
    #    /path/to/somewhere
    #
    # @param [String] url_to_secure url that shall be converted to use HTTPS
    # @raise ArgumentError if url is not absolute, starts with a '/'
    # @return [String] url with HTTPS scheme
    def secure_url(url_to_secure)
      # return if URL already is secure
      return url_to_secure if url_to_secure =~ /\A#{URI::regexp(['https'])}\z/
      throw ArgumentError, "Invalid URL '#{url_to_secure}', can't secure relative URL" if url_to_secure.start_with?('/')
      uri = URI.parse(url_to_secure)
      if uri.scheme.nil?
        uri = "https://#{url_to_secure}"
        secured_url = uri.to_s
      elsif uri.scheme != 'https'
        uri.scheme = 'https'
        secured_url = uri.to_s
      end
      secured_url
    end
  end
end
