class CreateLedgerEntries < ActiveRecord::Migration[7.2]
  def up
    create_table :ledger_entries do |t|
      t.references :leave_grant, null: false, foreign_key: true
      t.references :leave_period, foreign_key: true
      t.references :reverses_entry, foreign_key: { to_table: :ledger_entries }, index: false
      t.references :actor, foreign_key: { to_table: :employees } # null = Sistema (job)
      t.string :kind, null: false
      t.decimal :days, precision: 6, scale: 2, null: false
      t.date :effective_on, null: false
      t.text :reason, null: false
      t.string :source, null: false
      t.string :idempotency_key, null: false
      t.datetime :created_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
    end
    add_index :ledger_entries, :idempotency_key, unique: true
    # Un movimiento se revierte a lo más una vez.
    add_index :ledger_entries, :reverses_entry_id, unique: true, where: "reverses_entry_id IS NOT NULL"
    add_check_constraint :ledger_entries,
      "kind IN ('grant','usage','expiration','adjustment','reversal')", name: "ledger_entries_kind_check"
    add_check_constraint :ledger_entries, "days <> 0", name: "ledger_entries_days_non_zero"
    add_check_constraint :ledger_entries,
      "(kind = 'reversal') = (reverses_entry_id IS NOT NULL)", name: "ledger_entries_reversal_link"

    # R9: nada se borra ni se edita. Se refuerza en la base, no solo en el modelo.
    execute <<~SQL
      CREATE FUNCTION ledger_entries_append_only() RETURNS trigger AS $$
      BEGIN
        RAISE EXCEPTION 'ledger_entries es solo inserción: use un movimiento de reverso';
      END;
      $$ LANGUAGE plpgsql;

      CREATE TRIGGER ledger_entries_no_update_delete
        BEFORE UPDATE OR DELETE ON ledger_entries
        FOR EACH ROW EXECUTE FUNCTION ledger_entries_append_only();
    SQL
  end

  def down
    execute "DROP TRIGGER IF EXISTS ledger_entries_no_update_delete ON ledger_entries"
    execute "DROP FUNCTION IF EXISTS ledger_entries_append_only()"
    drop_table :ledger_entries
  end
end
