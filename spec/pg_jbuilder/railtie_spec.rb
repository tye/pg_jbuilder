require 'spec_helper'

describe PgJbuilder do
  describe 'PgJbuilder.paths' do
    subject { PgJbuilder.paths }
    it { is_expected.to include(Rails.root.join('app','queries')) }
  end
  describe 'PgJbuilder.connection' do
    subject { PgJbuilder.connection }
    it { is_expected.to be_kind_of(ActiveRecord::ConnectionAdapters::AbstractAdapter) }
  end
  context 'TestModel' do
    let(:variables) { {
      variable1: 1,
      variable2: 2
    } }
    describe '.select_value' do
      subject { TestModel }
      it { is_expected.to respond_to(:select_value) }
      it 'calls connection.select_value with query' do
        expect(PgJbuilder).to receive(:render).
          with('query_name', variables).and_return('TEST')
        expect(TestModel.connection).to receive(:select_value).
          with('TEST')
        TestModel.select_value 'query_name', variables
      end
    end
    describe '.select_array' do
      subject { TestModel }
      it { is_expected.to respond_to(:select_array) }
      it 'calls PgJbuilder.render_array' do
        expect(PgJbuilder).to receive(:render_array).
          with('query_name', variables)
        expect(TestModel.connection).to receive(:select_value)
        TestModel.select_array 'query_name', variables
      end
    end

    describe '.select_object' do
      subject { TestModel }
      it { is_expected.to respond_to(:select_object) }
      it 'calls PgJbuilder.render_object' do
        expect(PgJbuilder).to receive(:render_object).
          with('query_name', variables)
        expect(TestModel.connection).to receive(:select_value)
        TestModel.select_object 'query_name', variables
      end
    end

    describe "#select_value" do
      subject(:model) { TestModel.new }
      it { is_expected.to respond_to(:select_value) }

      it 'calls PgJbuilder.render' do
        expect(PgJbuilder).to receive(:render).
          with('query_name', variables).
          and_return('TEST')
        expect(TestModel.connection).to receive(:select_value).
          with('TEST')
        TestModel.select_value 'query_name', variables
      end
    end
    describe '#select_array' do
      subject(:model) { TestModel.new }
      it { is_expected.to respond_to(:select_array) }

      it 'calls PgJbuilder.render_array' do
        expect(PgJbuilder).to receive(:render_array).
          with('query_name', variables)
        expect(TestModel.connection).to receive(:select_value)
        model.select_array 'query_name', variables
      end
    end

    describe '#select_object' do
      subject(:model) { TestModel.new }
      it { is_expected.to respond_to(:select_object) }

      it 'calls PgJbuilder.render_object' do
        expect(PgJbuilder).to receive(:render_object).
          with('query_name', variables)
        expect(TestModel.connection).to receive(:select_value)
        model.select_object 'query_name', variables
      end
    end
  end
end

