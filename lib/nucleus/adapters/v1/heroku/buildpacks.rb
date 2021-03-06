module Nucleus
  module Adapters
    module V1
      class Heroku < Stub
        module Buildpacks
          include Nucleus::Adapters::BuildpackTranslator

          # @see BuildpackTranslator#vendor_specific_runtimes
          def vendor_specific_runtimes
            {
              'ruby' => 'https://github.com/heroku/heroku-buildpack-ruby',
              'nodejs' => 'https://github.com/heroku/heroku-buildpack-nodejs',
              'clojure' => 'https://github.com/heroku/heroku-buildpack-clojure',
              'python' => 'https://github.com/heroku/heroku-buildpack-python',
              'java' => 'https://github.com/heroku/heroku-buildpack-java',
              'gradle' => 'https://github.com/heroku/heroku-buildpack-gradle',
              'grails' => 'https://github.com/heroku/heroku-buildpack-grails',
              'scala' => 'https://github.com/heroku/heroku-buildpack-scala',
              'play' => 'https://github.com/heroku/heroku-buildpack-play',
              'php' => 'https://github.com/heroku/heroku-buildpack-php'
            }
          end
        end
      end
    end
  end
end
