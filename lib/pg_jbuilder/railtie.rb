module PgJbuilder
  class Railtie < Rails::Railtie
    initializer 'pg_jbuilder_rails_railtie.configure_rails_initialization' do
      ::PgJbuilder.paths.unshift Rails.root.join('app','queries')
    end
    
    initializer "pg_jbuilder_rails_railtie.configure_view_controller" do |app|
      ActiveSupport.on_load :active_record do
        include ActiveRecordExtension
        ::PgJbuilder.connection = lambda { ActiveRecord::Base.connection }
      end

      ActiveSupport.on_load :action_controller do
        include ActionControllerExtension
      end
    end
  end
  
  module ActionControllerExtension
    extend ActiveSupport::Concern
    
    def render_json_array(template, variables={})
      sql = ["-- query: #{template}"]
      sql << PgJbuilder.render_array(template, variables, include_query_name_comment: false)
      render json: PgJbuilder.connection.select_value(sql.join("\n"))
    end
    
    def render_json_object(template, variables={})
      sql = ["-- query: #{template}"]
      sql << PgJbuilder.render_object(template, variables, include_query_name_comment: false)
      render json: PgJbuilder.connection.select_value(sql.join("\n"))
    end
    
    def render_value(template, variables={})
      sql = ["-- query: #{template}"]
      sql << PgJbuilder.render(template, variables, include_query_name_comment: false)
      PgJbuilder.connection.select_value(sql.join("\n"))
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

