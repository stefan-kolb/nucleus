require 'filesize'
require 'time'

module Paasal
  module DB
    class Store
      include Paasal::Logging

      def initialize(api_version, store_type)
        @store_type = store_type
        @api_version = api_version
        @db = open_db
        # make sure DB gets closed
        at_exit do
          log.debug "Closing DB for #{store_type} and #{api_version}"
          @db.close
        end
      end

      def open_db
        # utilize the configured file store
        path = "#{configatron.db.path}"
        path << '/' unless configatron.db.path.end_with?(File::SEPARATOR)
        path << @api_version
        FileUtils.mkpath path
        Daybreak::DB.new("#{path}/#{@store_type}")
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

        @db.lock do
          @db.set!(entity.id, entity)
        end
        # return the updated and persisted entity
        entity
      end

      def delete(entity_id)
        @db.lock do
          if @db.key?(entity_id)
            # id was given, delete now
            @db.delete!(entity_id)
          else
            fail ResourceNotFoundError, "No #{@store_type} entity was found for the ID '#{entity_id}'." if id.nil?
          end
        end
      end

      def get_collection(entity_ids)
        response = []
        unless entity_ids.nil? && entity_ids.empty?
          entity_ids.each do |entity_id|
            response << @db.get(entity_id)
          end
        end
        response
      end

      def get(entity_id)
        @db.get(entity_id)
      end

      def all
        instances = []
        @db.each do |_id, value|
          instances << value
        end
        instances
      end

      def keys
        @db.keys
      end

      def key?(key)
        @db.key? key
      end

      def clear
        @db.lock do
          @db.clear unless @db.empty?
        end
      end

      private

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
