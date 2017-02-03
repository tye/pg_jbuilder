require 'spec_helper'

describe PgJbuilder, without_rails: true do
  after(:each) { PgJbuilder.clear_cache }
  describe '.connection' do
    subject { PgJbuilder.connection }
    it 'saves the connection' do
      PgJbuilder.connection = 'test'
      is_expected.to eq('test')
    end

    it 'executes a lambda' do
      PgJbuilder.connection = lambda{'lambda_test'}
      is_expected.to eq('lambda_test')
    end
  end

  describe '.render_array' do
    subject { PgJbuilder.render_array('template',defined?(variables) ? variables : {}) }
    it 'outputs as json object' do
      template = 'SELECT 1'
      expect(PgJbuilder).to receive(:render).
        and_return(template)
      result = "SELECT COALESCE(array_to_json(array_agg(row_to_json(array_row))),'[]'::json)\nFROM (\n#{template}\n) array_row"
      is_expected.to eq(result)
    end
  end

  describe '.render_object' do
    before :each do
      allow(PgJbuilder).to receive(:get_query_contents).
        and_return(template)
    end
    subject { PgJbuilder.render_object('template',defined?(variables) ? variables : {}) }
    let(:template) { "SELECT 1" }
    it 'outputs as json object' do
      result = "SELECT COALESCE(row_to_json(object_row),'{}'::json)\nFROM (\n#{template}\n) object_row"
      is_expected.to eq(result)
    end
  end

  describe '.render' do
    it 'returns the contents of the query file' do
      query_name = 'test'
      contents = "test query #{rand}"
      allow(PgJbuilder).to receive(:get_query_contents).
        with(query_name).and_return(contents)
      res = PgJbuilder.render query_name
      expect(res).to eq(contents)
    end

    it 'reads a query in queries directory' do
      query_path = File.join(File.dirname(__FILE__),'..','..','queries','test1.sql')
      res = PgJbuilder.render('test1')
      expect(res).to eq(File.read(query_path))
    end

    it 'reads a query from configured directories' do
      path = File.join(File.dirname(__FILE__),'..','queries')
      PgJbuilder.paths.unshift path
      res = PgJbuilder.render('test2')
      query_path = File.join(path,'test2.sql')
      expect(res).to eq(File.read(query_path))
    end

    context 'with a template that doesnt exist' do
      subject { PgJbuilder.render('template_does_not_exist') }
      it { expect{subject}.to raise_error(PgJbuilder::TemplateNotFound) }
    end

    context 'with a template' do
      before :each do
        allow(PgJbuilder).to receive(:get_query_contents).
          and_return(template)
      end
      subject { PgJbuilder.render('template',defined?(variables) ? variables : {}) }
      context 'with variables' do
        let(:template) {"<%= variable1 %>,<%= variable2 %>"}
        let(:variables) {
          {variable1: 'value_1',
           variable2: 'value_2'}
        }
        it 'substitutes the variables' do
          is_expected.to eq("value_1,value_2")
        end

        context 'that have HTML in them' do
          let(:variables) {
            {variable1: '<html>',
             variable2: '<body>'}
          }
          it 'doesn\'t escape the HTML' do
            is_expected.to eq("<html>,<body>")
          end
        end
      end # that has variables

      describe 'include helper' do
        let(:template) {"Included: <%= include 'included_template' %>"}
        let(:included_template) {"Included Template Contents"}
        before :each do
          allow(PgJbuilder).to receive(:get_query_contents).
            with('included_template').and_return(included_template)
        end
        it 'includes the included template' do
          is_expected.to eq("Included: Included Template Contents")
        end

        context 'with variables' do
          let(:variables) {
            {variable1: 'value_1',
             variable2: 'value_2'}
          }
          let(:included_template) {"Included Template <%= variable1 %>,<%= variable2 %>"}
          it 'the included template inherits the variables' do
            is_expected.to eq("Included: Included Template value_1,value_2")
          end

          context 'with variables in the include' do
            let(:template) {"Included: <%= include 'included_template', variable3: 'value_3', variable4: 'value_4' %>"}
            let(:included_template) {"Included Template <%= variable1 %>,<%= variable2 %>,<%= variable3 %>,<%= variable4 %>"}
            it 'the included template has the variables' do
              is_expected.to eq("Included: Included Template value_1,value_2,value_3,value_4")
            end
          end
        end # with include helper
      end

      describe 'quote helper' do
        let(:template) { 'Quoted: <%= quote variable1 %>' }
        let(:variables) do
          {variable1: 'String'}
        end
        it 'quotes a string' do
          is_expected.to eq("Quoted: 'String'")
        end
      end

      describe 'object helper' do
        let(:template) { "Object: <% object do %>\nObject Test\n<% end %>" }
        it 'renders object sql' do
          is_expected.to eq("Object: (SELECT COALESCE(row_to_json(object_row),'{}'::json) FROM (\nObject Test\n)object_row)")
        end
        context 'with template name' do
          let(:template) { "Object: <%= object 'object_template' %>" }
          let(:object_template) do
            "Object Template"
          end
          before :each do
            allow(PgJbuilder).to receive(:get_query_contents).
              with('object_template').and_return(object_template)
          end

          it 'renders object sql' do
            is_expected.to eq("Object: (SELECT COALESCE(row_to_json(object_row),'{}'::json) FROM (\nObject Template\n)object_row)")
          end
        end
      end # object helper

      describe 'array helper' do
        let(:template) { "Array: <% array do %>\nArray Test\n<% end %>" }
        it 'renders array sql' do
          is_expected.to eq("Array: (SELECT COALESCE(array_to_json(array_agg(row_to_json(array_row))),'[]'::json) FROM (\nArray Test\n)array_row)")
        end

        context 'with template name' do
          let(:template) { "Array: <%= array 'array_template' %>" }
          let(:array_template) do
            "Array Template"
          end
          before :each do
            allow(PgJbuilder).to receive(:get_query_contents).
              with('array_template').and_return(array_template)
          end

          it 'renders array sql' do
            is_expected.to eq("Array: (SELECT COALESCE(array_to_json(array_agg(row_to_json(array_row))),'[]'::json) FROM (\nArray Template\n)array_row)")
          end
        end
      end # array helper
    end
  end
end
