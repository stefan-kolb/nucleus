module Paasal
  module DB
    class CacheStore
      include Paasal::Logging

      def initialize(api_version, store_type)
        @store_type = store_type
        @api_version = api_version
        @db = open_db
        # make sure DB gets closed
        at_exit do
          log.debug "Closing DB for #{store_type} and #{api_version}"
          clear
          @db.close
        end
      end

      def set(key, value)
        @lock.synchronize do
          @db.store(key, value, expires: 120)
        end
        value
      end

      def delete(key)
        @lock.synchronize do
          if @db.key?(key)
            # id was given, delete now
            @db.delete(key)
          end
        end
      end

      def get(key)
        @db.load(key)
      end

      def key?(key)
        @db.key? key
      end

      def clear
        @lock.synchronize do
          @db.clear
        end
      end

      private

      def open_db
        store = Moneta.new(:LRUHash, expires: true)
        # use combined key of api version and store type
        @lock = Moneta::Mutex.new(store, "#{@api_version}.#{@store_type}")
        store
      end
    end
  end
end
