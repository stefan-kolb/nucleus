module Paasal
  module Adapters
    module V1
      class CloudFoundry2 < Stub
        module Buildpacks
          include Paasal::Adapters::BuildpackTranslator

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
