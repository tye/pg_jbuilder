class AddTestModel < ActiveRecord::Migration
  def change
    create_table :test_models do |t|
      t.string :field_string, null: false
      t.integer :field_int, null: false
      t.boolean :field_bool, null: false
      t.datetime :field_datetime, null: false
      t.timestamps
    end
  end
end
