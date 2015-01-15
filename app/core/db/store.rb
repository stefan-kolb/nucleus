require 'filesize'

module Paasal
  module DB
    class Store

      def initialize(api_version, store_type)
        @store_type = store_type
        @api_version = api_version
      end

      def use_db
        # utilize the configured file store
        path = "#{configatron.db.path}#{configatron.db.path.end_with?(File::SEPARATOR)?'':'/'}#{@api_version}"
        FileUtils.mkpath path
        db = Daybreak::DB.new("#{path}/#{@store_type}")
        yield db
      ensure
        db.close unless db.nil?
      end

      def set(entity)
        entity.id = SecureRandom.uuid if entity.id.nil?
        use_db do |db|
          db.lock do
            db.set!(entity.id, entity)
          end
        end
      end

      def delete(entity)
        use_db do |db|
          db.lock do
            db.delete!(entity.id)
          end
        end
      end

      def get(entity_id)
        use_db do |db|
          db.get(entity_id)
        end
      end

      def get_all
        instances = []
        use_db do |db|
          db.each do |id, value|
            instances << value
          end
        end
        instances
      end

      def keys
        use_db do |db|
          db.keys
        end
      end

    end
  end
end