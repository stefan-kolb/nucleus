RSpec::Core::Example.class_eval do
  alias_method :ignorant_run, :run

  def run(example_group_instance, reporter)
    if example_group_property(metadata, :em_reactor)
      # wrap in EM reactor
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
    else
      # default test execution
      ignorant_run(example_group_instance, reporter)
    end
  end

  def example_group_property(metadata, property)
    example_group_property = metadata.key?(:example_group) ? metadata[:example_group][property] : false
    parent_group_property = metadata.key?(:parent_example_group) ? metadata[:parent_example_group][property] : false

    # process recursive
    return example_group_property(metadata[:parent_example_group], property) if parent_group_property
    return metadata[:example_group] if example_group_property
    # property for the shared example group was not found
    nil
  end
end
