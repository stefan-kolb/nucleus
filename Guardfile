notification :terminal_notifier, activate: 'com.googlecode.iterm2', subtitle: 'Paasal - PaaS Abstraction Layer'
interactor :simple

guard 'bundler' do
  watch('Gemfile')
end

guard 'rack', :server => 'thin' do
  watch('Gemfile.lock')
  watch('config.ru')
  watch(%r{^config|app|public|lib|schemas|scripts/.*})
end

guard 'yard', :port => '8808', :cli => '--reload' do
  watch(%r{app/.+\.rb})
  watch(%r{lib/.+\.rb})
  watch(%r{.+\.md})
end