require 'rspec/core/rake_task'

namespace :evaluation do
  namespace :compatibility do
    task load: :environment do
      # TODO: choose API version
      api_version = 'v1'
      stub = Paasal::Adapters.const_get(api_version.upcase).const_get('Stub').new 'https://api.example.org'

      adapter_dao = Paasal::DB::AdapterDao.instance(api_version)
      endpoint_dao = Paasal::DB::EndpointDao.instance(api_version)
      provider_dao = Paasal::DB::ProviderDao.instance(api_version)
      vendor_dao = Paasal::DB::VendorDao.instance(api_version)
      @vendor_results = {}

      adapter_dao.all.each do |adapter_index_entry|
        vendor_name = vendor_dao.get(provider_dao.get(endpoint_dao.get(adapter_index_entry.id).provider).vendor).name
        next if @vendor_results.key?(vendor_name)
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
        @vendor_results[vendor_name] = adapter_results
      end
    end

    task markdown: :load do
      # table header
      puts "Method / Vendor|#{@vendor_results.keys.join('|')}"

      # column styles
      alignment = ':--'
      @vendor_results.length.times { |_time| alignment << '|:-:' }
      puts alignment

      lines = []
      @vendor_results.each do |_vendor, results|
        results.each_with_index do |(method, supported), line|
          lines[line] = "#{method}" unless lines[line]
          lines[line] << "|#{supported}"
        end
      end

      lines.each do |line|
        puts line
      end
    end

    task :latex, [:save_to] => :load do |_t, args|
      all_lines = []
      all_lines << "\\begin{longtable}{|L{7cm}|#{'c|' * @vendor_results.length}}"
      next_line = '  \\multicolumn{1}{l}{\\Large{\\textbf{Adapter compatibility}}}'
      @vendor_results.keys.each do |vendor|
        next_line += " & \\multicolumn{1}{l}{\\turn{60}{#{vendor}}}"
      end
      next_line += ' \\\\\\hline'
      all_lines << next_line
      all_lines << '  \\endhead'
      all_lines << '  \\rowcolor{white}'
      all_lines << '  \\caption{List of methods that are supported by PaaSal per vendor}'\
        '\\label{table:evaluation_adapter_compatibility}%'
      all_lines << '  \\endlastfoot'

      lines = []
      @vendor_results.each do |_vendor, results|
        results.each_with_index do |(method, supported), line|
          lines[line] = "#{method}" unless lines[line]
          lines[line] << " & #{supported ? '\\ding{51}' : '\\cellcolor{failedtablebg}{\\ding{55}}'}"
        end
      end

      # format and print all lines
      lines.each_with_index do |line, index|
        if index != lines.length - 1
          all_lines << "  #{line.gsub(/_/, '\_')} \\\\\\hline"
        else
          # special treatment for the last line
          all_lines << "  #{line.gsub(/_/, '\_')} \\\\\\hhline{|=|#{'=|' * @vendor_results.length}}"
        end
      end

      # print general statistics
      total_methods = @vendor_results.collect { |_v, tests| tests.length }.uniq.first
      supported_count = @vendor_results.collect { |_v, tests| tests.find_all { |_m, s| s }.length }
      all_lines << "  Supported methods & #{supported_count.join(' & ')} \\\\\\hline"
      to_print = supported_count.collect do |supported|
        "#{format('%g', format('%.1f', (supported / total_methods.to_f * 100)))} \\%"
      end

      all_lines << "  Supported degree & #{to_print.join(' & ')} \\\\\\hline"

      all_lines << '\\end{longtable}'

      # print lines
      all_lines.each { |line| puts line }

      # and save to file if requested
      File.open(args.save_to, 'w') { |file| file.write all_lines.join("\n") } if args.save_to
    end
  end
end
