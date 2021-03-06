module PgJbuilder
  class Railtie < Rails::Railtie
    initializer 'pg_jbuilder_rails_railtie.configure_rails_initialization' do
      ::PgJbuilder.paths.unshift Rails.root.join('app','queries')
      ActiveRecord::Base.send(:include, ActiveRecordExtension)
      PgJbuilder.connection = lambda { ActiveRecord::Base.connection }
    end
  end

  module ActiveRecordExtension
    extend ActiveSupport::Concern

    def select_array *args
      self.class.select_array(*args)
    end

    def select_object *args
      self.class.select_object(*args)
    end

    def select_value *args
      self.class.select_value(*args)
    end

    module ClassMethods

      def select_array name, variables={}
        sql = PgJbuilder.render_array name, variables
        connection.select_value sql
      end

      def select_object name, variables={}
        sql = PgJbuilder.render_object name, variables
        connection.select_value sql
      end

      def select_value name, variables={}
        sql = PgJbuilder.render name, variables
        connection.select_value sql
      end
    end
  end
end

