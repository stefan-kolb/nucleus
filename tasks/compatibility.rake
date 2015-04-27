require 'rspec/core/rake_task'

namespace :compatibility do
  task markdown: :environment do
    # TODO: choose API version
    api_version = 'v1'
    stub = Paasal::Adapters.const_get(api_version.upcase).const_get('Stub').new 'https://api.example.org'

    adapter_dao = Paasal::DB::AdapterDao.instance(api_version)
    endpoint_dao = Paasal::DB::EndpointDao.instance(api_version)
    provider_dao = Paasal::DB::ProviderDao.instance(api_version)
    vendor_dao = Paasal::DB::VendorDao.instance(api_version)
    vendor_results = {}

    adapter_dao.all.each do |adapter_index_entry|
      vendor_name = vendor_dao.get(provider_dao.get(endpoint_dao.get(adapter_index_entry.id).provider).vendor).name
      next if vendor_results.key?(vendor_name)
      adapter_results = {}
      adapter = adapter_index_entry.adapter_clazz.new('https://api.example.org', 'http://apps.example.org', true)
      stub.public_methods(false).each do |method_name|
        args = []
        method = stub.method(method_name)
        method.arity.times { |time| args.push(time) }
        begin
          adapter.send(method_name, *args)
          implemented = true
        rescue Paasal::Errors::AdapterMissingImplementationError
          implemented = false
        rescue StandardError
          implemented = true
        end
        adapter_results[method_name] = implemented
      end
      vendor_results[vendor_name] = adapter_results
    end

    # table header
    puts "Method / Vendor|#{vendor_results.keys.join('|')}"

    # column styles
    alignment = ':--'
    vendor_results.length.times { |_time| alignment << '|:-:' }
    puts alignment

    lines = []
    vendor_results.each do |_vendor, results|
      results.each_with_index do |(method, supported), line|
        lines[line] = "#{method}" unless lines[line]
        lines[line] << "|#{supported}"
      end
    end

    lines.each do |line|
      puts line
    end
  end
end
