module Nucleus
  module Adapters
    module V1
      class CloudFoundryV2 < Stub
        module Buildpacks
          include Nucleus::Adapters::BuildpackTranslator

          # @see BuildpackTranslator#vendor_specific_runtimes
          def vendor_specific_runtimes
            {
              'ruby' => 'ruby_buildpack',
              'nodejs' => 'nodejs_buildpack',
              'python' => 'python_buildpack',
              'java' => 'java_buildpack',
              'go' => 'go_buildpack',
              'php' => 'php_buildpack'
            }
          end
        end
      end
    end
  end
end
