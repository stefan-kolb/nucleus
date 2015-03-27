RSpec::Core::Example.class_eval do
  alias ignorant_run run

  def run(example_group_instance, reporter)
    @value_applied = false
    EM.run do
      Fiber.new do
        begin
          EM.add_timer(90) { fail Timeout::Error, 'aborting test due to timeout' }
          @ignorant_success = ignorant_run example_group_instance, reporter
        ensure
          @value_applied = true
          EM.stop
        end
      end.resume
    end
    # return test result
    @ignorant_success
  end
end
