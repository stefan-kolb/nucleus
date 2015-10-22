module Kernel
  def nucleus_config
    Configatron::RootStore.instance
  end
end
