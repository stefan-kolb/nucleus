module Paasal
  module Adapters
    # The {BuildpackTranslator} provides convenience methods for the user to handle the installation
    # of application runtimes. Common runtime names can be applied and are automatically translated to a
    # platform native runtime name / url (if applicable).
    module BuildpackTranslator
      # List of common buildpacks that are available GitHub.
      # However, they are not guaranteed to work with every platform that utilized buildpacks.
      PUBLIC_BUILDPACKS = {
        'c' => 'https://github.com/atris/heroku-buildpack-c',
        'common_lisp' => 'https://github.com/mtravers/heroku-buildpack-cl',
        'core_data' => 'https://github.com/heroku/heroku-buildpack-core-data',
        'dart' => 'https://github.com/igrigorik/heroku-buildpack-dart',
        'eiffel' => 'https://github.com/mbustosorg/heroku-buildpack-eiffel',
        'elixir' => 'https://github.com/hashnuke/heroku-buildpack-elixir',
        'emacs' => 'https://github.com/technomancy/heroku-buildpack-emacs',
        'embedded_proxy' => 'https://github.com/ryanbrainard/heroku-buildpack-embedded-proxy',
        'erlang' => 'https://github.com/archaelus/heroku-buildpack-erlang',
        'factor' => 'https://github.com/ryanbrainard/heroku-buildpack-factor',
        'fakesu' => 'https://github.com/fabiokung/heroku-buildpack-fakesu',
        'geodjango' => 'https://github.com/cirlabs/heroku-buildpack-geodjango',
        'go' => 'https://github.com/kr/heroku-buildpack-go',
        'haskell' => 'https://github.com/mietek/haskell-on-heroku',
        'inline' => 'https://github.com/kr/heroku-buildpack-inline',
        'java_ant' => 'https://github.com/dennisg/heroku-buildpack-ant',
        # introduced by IBM Bluemix, shall also work in Heroku
        'java_liberty' => 'https://github.com/cloudfoundry/ibm-websphere-liberty-buildpack',
        'jekyll' => 'https://github.com/mattmanning/heroku-buildpack-ruby-jekyll',
        'lua' => 'https://github.com/leafo/heroku-buildpack-lua',
        'luvit' => 'https://github.com/skomski/heroku-buildpack-luvit',
        'meteor' => 'https://github.com/jordansissel/heroku-buildpack-meteor',
        'middleman' => 'https://github.com/hashicorp/heroku-buildpack-middleman',
        'monit' => 'https://github.com/k33l0r/monit-buildpack',
        'multi' => 'https://github.com/heroku/heroku-buildpack-multi',
        'nanoc' => 'https://github.com/bobthecow/heroku-buildpack-nanoc',
        'dot_net' => 'https://github.com/friism/heroku-buildpack-mono',
        'null' => 'https://github.com/ryandotsmith/null-buildpack',
        'opa' => 'https://github.com/tsloughter/heroku-buildpack-opa',
        'perl' => 'https://github.com/miyagawa/heroku-buildpack-perl',
        'phantomjs' => 'https://github.com/stomita/heroku-buildpack-phantomjs',
        'phing' => 'https://github.com/ryanbrainard/heroku-buildpack-phing',
        'r' => 'https://github.com/virtualstaticvoid/heroku-buildpack-r',
        'rust' => 'https://github.com/emk/heroku-buildpack-rust',
        'redline' => 'https://github.com/will/heroku-buildpack-redline',
        'silex' => 'https://github.com/klaussilveira/heroku-buildpack-silex',
        'sphinx' => 'https://github.com/kennethreitz/sphinx-buildpack',
        'test' => 'https://github.com/ddollar/buildpack-test',
        'testing' => 'https://github.com/ryanbrainard/heroku-buildpack-testrunner'
      }

      # Search the list of known buildpacks, both vendor specific and public, to match the desires runtime name.
      # @param [String] name of the runtime to look out for
      # @return [Boolean] returns true if a vendor specific or public buildpack was found for the runtime
      def find_runtime(name)
        if respond_to? :vendor_specific_runtimes
          runtime = vendor_specific_runtimes[name.downcase.underscore]
          return runtime unless runtime.nil?
        end

        # if no vendor specific runtime was found, use the general definitions
        PUBLIC_BUILDPACKS[name.downcase.underscore]
      end

      # Checks if the name of the runtime is matching a vendor specific runtime / buildpack.
      # @param [String] name of the runtime for which to check if it matches a vendor specific runtime
      # @return [Boolean] returns true if the name matches a vendor specific runtime, false otherwise
      def native_runtime?(name)
        if respond_to? :vendor_specific_runtimes
          # case A: name is a key
          return true if vendor_specific_runtimes.keys.include? name
          # case B: name is a specific runtime name or a URL and one of the values
          return vendor_specific_runtimes.values.include? name
        end
        # cant be native if there are no vendor specific runtimes
        false
      end
    end
  end
end
