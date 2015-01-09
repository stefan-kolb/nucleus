# YAML based settings
# by Oleg Ivanov, see http://speakmy.name/2011/05/29/simple-configuration-for-ruby-apps/
module Settings
  # singleton, thus implemented as a self-extended module
  extend self

  @_settings = {}
  attr_reader :_settings

  # Call Settings.load! to read the config
  def load!(filename)
    yamlConfig = YAML::load_file(filename).deep_symbolize
    deep_merge!(@_settings, yamlConfig)
  end

  # Deep merging of hashes
  # deep_merge by Stefan Rusterholz, see http://www.ruby-forum.com/topic/142809
  def deep_merge!(target, data)
    merger = proc{|key, v1, v2|
      Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : v2 }
    target.merge! data, &merger
  end

  def method_missing(name, *args, &block)
    @_settings[name.to_sym] ||
        fail(NoMethodError, "unknown configuration root #{name}", caller)
  end

end
