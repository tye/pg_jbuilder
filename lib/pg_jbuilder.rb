require 'pg_jbuilder/version'
require 'handlebars'
require 'pg_jbuilder/railtie' if defined?(Rails)

module PgJbuilder
  @paths = [
    File.join(File.dirname(__FILE__),'..','queries')
  ]
  class TemplateNotFound < ::Exception; end

  def self.render_object *args
    result = render(*args)
    "SELECT COALESCE(row_to_json(object_row),'{}'::json)\nFROM (\n#{result}\n) object_row"
  end

  def self.render_array *args
    result = render(*args)
    "SELECT COALESCE(array_to_json(array_agg(row_to_json(array_row))),'[]'::json)\nFROM (\n#{result}\n) array_row"
  end


  def self.render query, variables={}, options={}
    contents = get_query_contents(query)
    compiled = handlebars.compile(contents, noEscape: true)
    compiled.call(variables)
  end

  def self.paths
    @paths
  end

  def self.connection= value
    @connection = value
  end

  def self.connection
    if @connection.is_a?(Proc)
      @connection.call
    else
      @connection
    end
  end

  private

  def self.get_query_contents query
    File.read path_name(query)
  end

  def self.path_name *args
    last_arg = args.pop
    query_name = last_arg
    last_arg += '.sql'
    args.push last_arg
    @paths.each do |path|
      file = File.join(path,*args)
      if File.exists?(file) && File.file?(file)
        return file
      end
    end
    raise TemplateNotFound.new("Template #{query_name} was not found in any source paths")
  end

  def self.render_helper context, value, options
    variables = Hash[context.collect{|k,v|[k,v]}]
    options['hash'].each{|k,v| variables[k] = v} if options
    PgJbuilder.render value, variables
  end

  def self.handlebars
    unless @handlebars
      @handlebars = Handlebars::Context.new
      @handlebars.register_helper :include do |context,value,options|
        render_helper context, value, options
      end

      @handlebars.register_helper :quote do |context,value,options|
        connection.quote value
      end

      @handlebars.register_helper :object do |context,value,options|
        if value.is_a?(String)
          content = render_helper(context,value,options)
          content = "\n#{content}\n"
        else
          content = value.fn(context)
        end
        "(SELECT COALESCE(row_to_json(object_row),'{}'::json) FROM (" +
          content +
          ")object_row)"
      end

      @handlebars.register_helper :array do |context,value,options|
        if value.is_a?(String)
          content = render_helper(context,value,options)
          content = "\n#{content}\n"
        else
          content = value.fn(context)
        end
        "(SELECT COALESCE(array_to_json(array_agg(row_to_json(array_row))),'[]'::json) FROM (" +
          content +
          ")array_row)"
      end
    end
    @handlebars
  end
end

