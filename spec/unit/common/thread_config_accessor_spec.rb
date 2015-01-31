require 'app/core/thread_config_accessor'

class ThreadedConfig
  thread_config_accessor :setting_a, default: 5
end

class ThreadedConfigParentA
end

class ThreadedConfigParentB
  thread_config_accessor :setting_a, default: 13
end

class ThreadedConfigChildA < ThreadedConfigParentA
  thread_config_accessor :setting_a, default: 11
end

class ThreadedConfigChildB < ThreadedConfigParentB
end

class ThreadedConfigReadOnly
  thread_config_accessor_readonly :setting_a, default: 7
end

describe 'ThreadConfigAccessor' do
  describe 'config values accessibility' do
    it 'for config defined in base class shall be available to inheriting classes' do
      child = ThreadedConfigChildB.new
      expect(child.setting_a).to eql 13
      child.setting_a = 17
      expect(child.setting_a).to eql 17
      expect(child.setting_a).to eql ThreadedConfigParentB.setting_a
      ThreadedConfigParentB.setting_a = 19
      expect(child.setting_a).to eql ThreadedConfigParentB.setting_a
      expect(child.setting_a).to eql 19
    end

    it 'for config defined in inheriting class shall not be available to parent classes' do
      child = ThreadedConfigChildA.new
      expect(child.setting_a).to eql 11
      expect { ThreadedConfigParentA.setting_a }.to raise_error(NoMethodError)
    end
  end

  describe 'using #thread_config_accessor' do
    before :all do
      # create instance
      @config = ThreadedConfig.new
      # assign value to the class
      ThreadedConfig.setting_a = 1
    end

    it 'should have the same value on the class and instance' do
      expect(@config.setting_a).to eql 1
      expect(@config.setting_a).to eql ThreadedConfig.setting_a
    end

    it 'should have the different values in a new thread' do
      Thread.new do
        @config.setting_a = 2
        expect(@config.setting_a).to eql 2
        expect(@config.setting_a).to eql ThreadedConfig.setting_a
      end.join
    end

    it 'should have the default values in a new thread' do
      Thread.new do
        expect(@config.setting_a).to eql 5
        expect(@config.setting_a).to eql ThreadedConfig.setting_a
      end.join
    end
  end

  describe 'using #thread_config_accessor_readonly' do
    before :all do
      # create instance
      @config = ThreadedConfigReadOnly.new
    end

    it 'should have the same value on the class and instance' do
      expect(@config.setting_a).to eql 7
      expect(@config.setting_a).to eql ThreadedConfigReadOnly.setting_a
    end

    it 'should keep the same default values in a new thread' do
      Thread.new do
        expect(@config.setting_a).to eql 7
        expect(@config.setting_a).to eql ThreadedConfigReadOnly.setting_a
      end.join
    end

    it 'should not allow to change the default values' do
      Thread.new { expect { @config.setting_a = 10 }.to raise_error }.join
    end
  end
end
