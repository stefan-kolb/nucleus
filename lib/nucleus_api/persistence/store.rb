module Nucleus
  module DB
    class Store
      include Nucleus::Logging

      def initialize(api_version, store_type)
        @store_type = store_type
        @api_version = api_version
        @db = open_db
        @restricted_index_key = "nucleus.store.index.for.api.#{api_version}.and.type.#{store_type}"
        # make sure DB gets closed
        at_exit do
          log.debug "Closing DB for #{store_type} and #{api_version}"
          @db.close
        end
      end

      def set(entity)
        update_timestamps(entity)

        # finally save to the DB
        if entity.id.nil?
          loop do
            # assign unique ID (only for entities added via the API)
            entity.id = SecureRandom.uuid if entity.id.nil?
            break unless @db.key? entity.id
          end
        end

        raise StandardError, "Cant modify restricted key '#{entity.id}'" if entity.id.to_s == @restricted_index_key

        @lock.synchronize do
          @db.store(entity.id, entity)
          # update the index
          add_key_to_index(entity.id)
        end
        # return the updated and persisted entity
        entity
      end

      def delete(entity_id)
        raise StandardError, "Cant modify restricted key '#{entity_id}'" if entity_id.to_s == @restricted_index_key
        @lock.synchronize do
          if @db.key?(entity_id)
            # id was given, delete now
            @db.delete(entity_id)
            # update the index
            remove_key_from_index(entity_id)
          elsif id.nil?
            raise ResourceNotFoundError, "No #{@store_type} entity was found for the ID '#{entity_id}'."
          end
        end
      end

      def get_collection(entity_ids)
        response = []
        unless entity_ids.nil? || entity_ids.empty?
          entity_ids.each do |entity_id|
            raise StandardError, "Cant load restricted key '#{entity_id}'" if entity_id.to_s == @restricted_index_key
            response << @db.load(entity_id)
          end
        end
        response
      end

      def get(entity_id)
        raise StandardError, "Cant load restricted key '#{entity_id}'" if entity_id.to_s == @restricted_index_key
        @db.load(entity_id)
      end

      def all
        instances = []
        index.each do |key|
          instances << @db.load(key)
        end
        instances
      end

      def keys
        index.to_a
      end

      def key?(key)
        raise StartupError, "Cant load restricted key '#{key}'" if key.to_s == @restricted_index_key
        @db.key? key
      end

      def clear
        @lock.synchronize do
          @db.clear
        end
      end

      def allowed_backends
        { LMDB: { dir: path, db: @store_type } }
      end

      private

      def path
        File.join(nucleus_config.db.path.chomp('/').chomp('\\'), @api_version)
      end

      def chosen_db_backend
        return nucleus_config.db.backend if nucleus_config.db.key?(:backend)
        :LMDB
      end

      def open_db
        db_backend = chosen_db_backend

        unless allowed_backends.key?(db_backend)
          raise StandardError,
                "Invalid database backend '#{db_backend}'. Please choose one of: #{allowed_backends.keys}"
        end

        backend_options = if nucleus_config.db.key?(:backend_options)
                            allowed_backends[db_backend].merge(nucleus_config.db.backend_options)
                          else
                            allowed_backends[db_backend]
                          end

        # Create the path if we use directories or files
        if backend_options.key?(:file)
          FileUtils.mkpath path
        elsif backend_options.key?(:dir)
          FileUtils.mkpath backend_options[:dir]
        end

        store = Moneta.new(db_backend, backend_options)
        # use combined key of api version and store type
        @lock = Moneta::Mutex.new(store, "#{@api_version}.#{@store_type}")
        store
      end

      def index
        @db.fetch(@restricted_index_key, Set.new)
      end

      def add_key_to_index(key)
        keys = index
        # add key to index
        keys.add(key)
        @db.store(@restricted_index_key, keys)
      end

      def remove_key_from_index(key)
        keys = index
        # remove key from index
        keys.delete(key)
        @db.store(@restricted_index_key, keys)
      end

      def update_timestamps(entity)
        now = Time.now.utc.iso8601
        if entity.respond_to?(:created_at) && entity.created_at.nil?
          # assign created timestamp
          entity.created_at = now if entity.respond_to?(:created_at=)
        end
        # assign update timestamp
        entity.updated_at = now if entity.respond_to?(:updated_at=)
      end
    end
  end
end
