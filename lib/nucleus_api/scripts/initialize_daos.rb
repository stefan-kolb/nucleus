# set the temporary db file if is has not been specified via the config
unless nucleus_config.db.key?(:path)
  puts 'No custom DB store specified, generating temporary store filename'
  nucleus_config.db.path = "#{Dir.tmpdir}/#{SecureRandom.uuid}.nucleus.store"
end

log.info "DB store assigned to #{nucleus_config.db.path}"

# load vendors and put them into the db stores
Nucleus::API::AdapterImporter.new.import

nucleus_config.api.versions.each do |api_version|
  puts '', "Bootstraping DAOs for Nucleus #{api_version}..."
  # Bootstrap DAOs for each API version
  Nucleus::API::DB::VendorDao.instance api_version
  Nucleus::API::DB::ProviderDao.instance api_version
  Nucleus::API::DB::EndpointDao.instance api_version
  Nucleus::API::DB::AdapterDao.instance api_version
  Nucleus::API::DB::CacheDao.instance api_version
end
