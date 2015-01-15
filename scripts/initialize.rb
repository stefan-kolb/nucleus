begin
  # set the temporary db file if is has not been specified via the config
  unless configatron.db.has_key?(:path)
    puts 'No custom store specified, generating temporary store filename'
    configatron.db.path = "#{Dir.tmpdir}/#{SecureRandom.uuid}.paasal.store"
  end
  puts "DB store assigned to #{configatron.db.path}"

  # TODO load vendors and put them into the db stores
  # TODO check if the store is empty or shall be overridden

  adapter_loader = Paasal::AdapterImporter.new
  adapter_loader.import_adapters

  # Check the API versions once and make them available via configatron
  api_detector = Paasal::ApiDetector.new
  configatron.api.versions = api_detector.get_api_versions

  # Lock the configuration, so it can't be manipulated
  configatron.lock!
  puts 'Initialization complete & configuration locked!'
  puts '-----------------------------------------------', ''

  # TODO DEBUG CODE TO VISUALISE THE LOADED DB STATE

  ["v1", "v2"].each do |api_version|
    puts '', "API #{api_version}:"
    vendor_dao = Paasal::DB::VendorDao.new api_version
    provider_dao = Paasal::DB::ProviderDao.new api_version
    endpoint_dao = Paasal::DB::EndpointDao.new api_version

    p 'All vendors:'
    vendor_dao.keys.each do |key|
      p vendor_dao.get key
    end

    p 'All providers:'
    provider_dao.keys.each do |key|
      p provider_dao.get key
    end

    p 'All endpoints:'
    endpoint_dao.keys.each do |key|
      p endpoint_dao.get key
    end
  end

rescue Paasal::StartupError => e
  puts 'Application startup failed, exit now'
  exit e.exit_code
end

# TODO check if all adapters respond to the required methods
# TODO load all adapters !?
# TODO determine API versions