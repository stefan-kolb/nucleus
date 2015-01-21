notification :terminal_notifier, activate: 'com.googlecode.iterm2', subtitle: 'Paasal - PaaS Abstraction Layer'
interactor :simple

guard 'bundler' do
  watch('Gemfile')
end

guard 'rack', :server => 'thin' do
  watch('Gemfile.lock')
  watch('config.ru')
  watch(/^config|app|public|lib|schemas|scripts\\/.*)
end

guard 'yard', :port => '8808', :cli => '--reload' do
  watch(/app\/.+\.rb/)
  watch(/lib\/.+\.rb/)
  watch(/.+\.md/)
end

guard :rubocop do
  watch(/.+\.rb$/)
  watch(/(?:.+\/)?\.rubocop\.yml$/) { |m| File.dirname(m[0]) }
end
