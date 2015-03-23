module Paasal
  module Adapters
    module V1
      class CloudControl < BaseAdapter
        module Buildpacks
          include Paasal::Adapters::BuildpackTranslator

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
