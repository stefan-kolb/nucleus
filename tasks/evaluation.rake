require 'rspec/core/rake_task'
require 'oj'

namespace :evaluation do
  namespace :requests do
    namespace :count do
      desc 'Load the data that will be used in the request evaluation tasks'
      task load: :environment do
        # TODO: choose API version
        api_version = 'v1'

        adapter_dao = Paasal::DB::AdapterDao.instance(api_version)
        endpoint_dao = Paasal::DB::EndpointDao.instance(api_version)
        provider_dao = Paasal::DB::ProviderDao.instance(api_version)
        vendor_dao = Paasal::DB::VendorDao.instance(api_version)
        @vendor_results = {}

        adapter_dao.all.each do |adapter_index_entry|
          vendor_name = vendor_dao.get(provider_dao.get(endpoint_dao.get(adapter_index_entry.id).provider).vendor).name
          # from camel to sneak case
          adapter_file_name = vendor_name.gsub(/\s/, '_').gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
                              .gsub(/([a-z\d])([A-Z])/, '\1_\2').downcase
          next if @vendor_results.key?(vendor_name)
          adaper_results = {}

          method_recordings_dir = File.join('spec', 'adapter', 'recordings', api_version, adapter_file_name,
                                            'vcr_cassettes', 'with_valid_credentials', 'is_compliant_and')
          Find.find(method_recordings_dir) do |file|
            next if File.directory?(file) || File.basename(file) == '.DS_Store'
            test = Pathname.new(file).relative_path_from(Pathname.new(method_recordings_dir)).to_s
            # Load contents with the serializer, oj
            cassette = ::Oj.load(File.read(file))
            adaper_results[test] = cassette['http_interactions'].length
          end
          @vendor_results[vendor_name] = adaper_results
        end

        @all_tests = @vendor_results.collect { |_name, tests| tests.keys }.flatten.uniq
      end

      task markdown: :load do
        # table header
        puts "Test / Vendor|#{@vendor_results.keys.join('|')}"

        # column styles
        alignment = ':--'
        @vendor_results.length.times { |_time| alignment << '|:-:' }
        puts alignment

        lines = []
        @all_tests.sort.each_with_index do |test_name, line|
          @vendor_results.each do |_vendor, results|
            lines[line] = "#{test_name}" unless lines[line]
            lines[line] << "|#{results[test_name]}"
          end
        end

        lines.each do |line|
          puts line
        end

        # table header
        puts '|' * @vendor_results.length
        puts "Test / Vendor|#{@vendor_results.keys.join('|')}"
        puts '|' * @vendor_results.length
        puts "Tested methods|#{@vendor_results.collect { |_name, tests| tests.length }.join('|')}"
        puts "Total vendor API requests|#{@vendor_results.collect do |_name, tests|
          tests.map { |_key, value| value }.sum
        end.join('|')}"
        puts "Avg. vendor API requests per tested method|#{@vendor_results.collect do |_name, tests|
          ((tests.map { |_key, value| value }.sum) / tests.length.to_f).round(2)
        end.join('|')}"
      end

      task :latex, [:save_to] => :load do |_t, args|
        table = []
        table << "\\scriptsize{\\begin{longtable}{|L{12cm}|#{'c|' * @vendor_results.length}}"
        next_line = '  \\multicolumn{1}{l}{\\Large{\\textbf{recorded test cassette}}}'
        @vendor_results.keys.each do |vendor|
          next_line += " & \\multicolumn{1}{l}{\\turn{60}{#{vendor}}}"
        end
        next_line += ' \\\\\\hline'
        table << next_line
        table << '  \\endhead'
        table << '  \\rowcolor{white}'
        table << '  \\caption{Requests per method test case for all vendors}'\
          '\\label{table:evaluation_request_count}%'
        table << '  \\endlastfoot'

        lines = []
        @all_tests.sort.each_with_index do |test_name, line|
          @vendor_results.each do |_vendor, results|
            lines[line] = "#{test_name}" unless lines[line]
            lines[line] << " & #{results[test_name]}"
          end
        end

        # format and print all lines
        lines.each_with_index do |line, index|
          if index != lines.length - 1
            table << "  #{line.gsub(/_/, '\_')} \\\\\\hline"
          else
            # special treatment for the last line
            table << "  #{line.gsub(/_/, '\_')} \\\\\\hhline{|=|#{'=|' * @vendor_results.length}}"
          end
        end

        # print general statistics
        table << "  Tested methods & #{@vendor_results.collect { |_n, tests| tests.length }.join(' & ')} \\\\\\hline"
        table << "  Total vendor API requests & #{@vendor_results.collect do |_name, tests|
          tests.map { |_key, value| value }.sum
        end.join(' & ')} \\\\\\hline"
        table << "  Avg. vendor API requests per tested method & #{@vendor_results.collect do |_name, tests|
          ((tests.map { |_key, value| value }.sum) / tests.length.to_f).round(2)
        end.join(' & ')} \\\\\\hline"

        table << '\\end{longtable}}'

        # print lines
        table.each { |line| puts line }

        # and save to file if requested
        File.open(args.save_to, 'w') { |file| file.write table.join("\n") } if args.save_to
      end
    end
  end
end
