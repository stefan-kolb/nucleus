module Paasal
  module Adapters
    module V1
      class CloudControl < Stub
        # cloud control specific buildpacks
        module Buildpacks
          include Paasal::Adapters::BuildpackTranslator

          # @see BuildpackTranslator#vendor_specific_runtimes
          def vendor_specific_runtimes
            {
              'java' => 'java',
              'nodejs' => 'nodejs',
              'ruby' => 'ruby',
              'php' => 'php',
              'python' => 'python'
            }
          end
        end
      end
    end
  end
end