class CreateLeaveTypesAndBatches < ActiveRecord::Migration[7.2]
  def change
    # Policies as data (Part 2): HR creates types without development.
    create_table :leave_types do |t|
      t.references :company, null: false, foreign_key: true
      t.string :name, null: false
      t.string :code, null: false
      # Pool days are spent from: "vacation" (legal + progressive), "administrative", etc.
      t.string :pool, null: false
      t.string :grant_mode, null: false, default: "manual"          # rule | manual
      t.string :expiration_policy, null: false, default: "none"    # none | fixed_date | relative
      t.string :expiration_value                                   # "12-31" | "2y" | "6m" | "90d"
      t.boolean :system, null: false, default: false               # legal types, not editable
      t.boolean :active, null: false, default: true
      t.integer :position, null: false, default: 100
      t.timestamps
    end
    add_index :leave_types, [:company_id, :code], unique: true
    add_check_constraint :leave_types, "grant_mode IN ('rule','manual')", name: "leave_types_grant_mode_check"
    add_check_constraint :leave_types, "expiration_policy IN ('none','fixed_date','relative')", name: "leave_types_expiration_policy_check"

    create_table :grant_batches do |t|
      t.references :company, null: false, foreign_key: true
      t.references :leave_type, null: false, foreign_key: true
      t.references :created_by, null: false, foreign_key: { to_table: :employees }
      t.decimal :days, precision: 6, scale: 2, null: false
      t.date :granted_on, null: false
      t.text :reason, null: false
      t.string :target_description
      t.datetime :created_at, null: false
    end
  end
end
