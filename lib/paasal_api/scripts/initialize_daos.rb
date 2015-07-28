# set the temporary db file if is has not been specified via the config
unless paasal_config.db.key?(:path)
  puts 'No custom DB store specified, generating temporary store filename'
  paasal_config.db.path = "#{Dir.tmpdir}/#{SecureRandom.uuid}.paasal.store"
end

log.info "DB store assigned to #{paasal_config.db.path}"

# load vendors and put them into the db stores
Paasal::API::AdapterImporter.new.import

paasal_config.api.versions.each do |api_version|
  puts '', "Bootstraping DAOs for PaaSal #{api_version}..."
  # Bootstrap DAOs for each API version
  Paasal::API::DB::VendorDao.instance api_version
  Paasal::API::DB::ProviderDao.instance api_version
  Paasal::API::DB::EndpointDao.instance api_version
  Paasal::API::DB::AdapterDao.instance api_version
  Paasal::API::DB::CacheDao.instance api_version
end