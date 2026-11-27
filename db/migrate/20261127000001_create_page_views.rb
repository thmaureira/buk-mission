# Usage metrics: one row per request handled by the app (no IP is stored).
class CreatePageViews < ActiveRecord::Migration[7.2]
  def change
    create_table :page_views do |t|
      t.string :visitor_id, null: false # random id in a signed cookie, one per browser
      t.references :actor, foreign_key: { to_table: :employees } # who "Ver como" was set to
      t.string :actor_role
      t.string :request_method, null: false
      t.string :path, null: false
      t.string :controller_action, null: false
      t.integer :status, null: false
      t.boolean :external, null: false, default: false # came through the ngrok tunnel
      t.datetime :created_at, null: false
    end
    add_index :page_views, :created_at
    add_index :page_views, :visitor_id
  end
end
