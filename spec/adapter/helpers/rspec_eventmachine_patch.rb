RSpec::Core::Example.class_eval do
  alias_method :ignorant_run, :run

  def run(example_group_instance, reporter)
    @value_applied = false
    EM.run do
      Fiber.new do
        begin
          EM.add_timer(60) do
            @timeout_error = Timeout::Error.new('aborting test due to timeout')
            EM.stop
          end
          @ignorant_success = ignorant_run(example_group_instance, reporter)
        ensure
          @value_applied = true
          EM.stop
        end
      end.resume
    end
    # was there a timeout in the EM loop? then fail!
    fail @timeout_error if @timeout_error
    # return test result
    @ignorant_success
  end
end
