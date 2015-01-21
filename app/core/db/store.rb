require 'filesize'
require 'time'

module Paasal
  module DB
    class Store

      def initialize(api_version, store_type)
        @store_type = store_type
        @api_version = api_version
      end

      def use_db
        # utilize the configured file store
        path = configatron.db.path
        path << '/' unless configatron.db.path.end_with?(File::SEPARATOR)
        path << @api_version
        FileUtils.mkpath path
        db = Daybreak::DB.new("#{path}/#{@store_type}")
        yield db
      ensure
        db.close unless db.nil?
      end

      def set(entity)
        update_timestamps(entity)

        # finally save to the DB
        use_db do |db|
          if entity.id.nil?
            loop do
              # assign unique ID (only for entities added via the API)
              entity.id = SecureRandom.uuid if entity.id.nil?
              break unless db.key? entity.id
            end
          end

          db.lock do
            db.set!(entity.id, entity)
          end
        end
      end

      def delete(entity_id)
        # TODO cascade delete for vendor --> provider --> endpoint in the controller
        use_db do |db|
          db.lock do
            if db.key?(entity_id)
              # id was given, delete now
              db.delete!(entity_id)
            else
              raise ResourceNotFoundError, "No #{@store_type} entity was found for the ID '#{entity_id}'." if id.nil?
            end
          end
        end
      end

=begin
      def delete(entity_id_or_key)
        # TODO cascade delete for vendor --> provider --> endpoint
        use_db do |db|
          db.lock do
            if db.key?(entity_id_or_key)
              # id was given, delete now
              db.delete!(entity_id_or_key)
            else
              # we need to search for the entity with this key to get the id
              db.each do |key, value|
                id = key if value == entity_id_or_key
                break unless id.nil?
              end
              raise ResourceNotFoundError, "Neither an ID, nor a key was found for '#{entity_id_or_key}'." if id.nil?
              db.delete!(id)
            end
          end
        end
      end
=end

      def get_collection(entity_ids)
        response = []
        use_db do |db|
          entity_ids.each do |entity_id|
            response << db.get(entity_id)
          end
        end unless entity_ids.nil? && entity_ids.empty?
        response
      end

      def get(entity_id)
        use_db do |db|
          db.get(entity_id)
        end
      end

      def get_all
        instances = []
        use_db do |db|
          db.each do |_id, value|
            instances << value
          end
        end
        instances
      end

      def keys
        use_db(&:keys)
      end

      def key?(key)
        use_db do |db|
          db.key? key
        end
      end

      private

      def update_timestamps(entity)
        now = Time.now.utc.iso8601
        if entity.respond_to?(:created_at) && entity.created_at.nil?
          # assign created timestamp
          entity.created_at = now if entity.respond_to?(:updated_at=)
        end
        if entity.respond_to?(:updated_at)
          # assign update timestamp
          entity.updated_at = now if entity.respond_to?(:updated_at=)
        end
      end

    end
  end
end