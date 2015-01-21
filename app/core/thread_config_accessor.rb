# Redefines the Class and provides the thread_lib_accessor.
#
# If invoked with a variable name, the class and its instances can be used
# as a key-value config for that variable name.
# E.g.:
#    class ThreadedConfig
#      thread_config_accessor :some_setting, :default => 5
#    end
#
#    class TestThreadedConfig < Test::Unit::TestCase
#      def test_that_the_accessors_work!
#        # create instance
#        config = ThreadedConfig.new
#        # assign value to the class
#        ThreadedConfig.setting_a = 1
#
#        # value is equal for both, class and instance
#        assert_equal 1, ThreadedConfig.setting_a
#        assert_equal 1, config.setting_a
#
#        # create new Thread, which should NOT have the values assigned
#        Thread.new {
#          config.setting_a = 2
#          assert_equal 2, ThreadedConfig.setting_a
#          assert_equal 2, config.setting_a
#        }.join
#
#        # create new Thread and assert the default value was assigned
#        Thread.new { assert_equal 5, ThreadedConfig.setting_a }.join
#
#        assert_equal 1, ThreadedConfig.setting_a
#      end
#    end
#
# By coderrr (Steve), see https://coderrr.wordpress.com/2008/04/10/lets-stop-polluting-the-threadcurrent-hash/
class Class

  # Binds accessors to the class and its instances and allows to use them as thread-bound config
  def thread_config_accessor name, options = {}
    mod = Module.new
    mod.module_eval do
      class_variable_set :"@@#{name}", Hash.new { |h, k| h[k] = options[:default] }
    end

    # use finalizer to prevent memory leaks and clean-up when threads die
    mod.module_eval %{
      FINALIZER = lambda {|id| @@#{name}.delete id }

      def #{name}
        @@#{name}[Thread.current.object_id]
      end

      def #{name}=(val)
        ObjectSpace.define_finalizer Thread.current, FINALIZER  unless @@#{name}.has_key? Thread.current.object_id
        @@#{name}[Thread.current.object_id] = val
      end
    }

    class_eval do
      include mod
      extend mod
    end
  end

  # Binds accessors to the class and its instances and allows to use them as (read-only) thread-bound config
  def thread_config_accessor_readonly name, options = {}
    mod = Module.new
    mod.module_eval do
      class_variable_set :"@@#{name}", Hash.new { |h, k| h[k] = options[:default] }
    end

    # use finalizer to prevent memory leaks and clean-up when threads die
    mod.module_eval %{
      FINALIZER = lambda {|id| @@#{name}.delete id }

      def #{name}
        @@#{name}[Thread.current.object_id]
      end
    }

    class_eval do
      include mod
      extend mod
    end
  end
end
