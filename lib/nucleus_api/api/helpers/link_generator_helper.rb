module Nucleus
  module API
    module LinkGeneratorHelper
      extend Grape::API::Helpers

      def link_generator
        return RequestStore.store[:link_generator] if RequestStore.exist?(:link_generator)
        # create new instance of the link generator for the request
        link_generator = Nucleus::LinkGenerator.new(env, version)
        RequestStore.store[:link_generator] = link_generator
        link_generator
      end
    end
  end
end
