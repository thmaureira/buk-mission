class CreateHolidaysAndRuleVersions < ActiveRecord::Migration[7.2]
  def change
    create_table :holidays do |t|
      t.date :date, null: false
      t.string :name, null: false
      t.string :scope, null: false, default: "national" # national | regional
      t.string :region
      t.timestamps
    end
    add_index :holidays, [:date, :scope, :region], unique: true

    # Strategy: one class per rule and effective date.
    create_table :rule_versions do |t|
      t.string :country, null: false, default: "CL"
      t.string :rule_key, null: false       # legal_days | progressive_days | proportional_days
      t.string :strategy, null: false       # Ruby class name
      t.date :effective_from, null: false
      t.string :notes
      t.timestamps
    end
    add_index :rule_versions, [:country, :rule_key, :effective_from], unique: true
  end
end
