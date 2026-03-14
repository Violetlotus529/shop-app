class AddUniqIndexToStripeEvents < ActiveRecord::Migration[7.1]
  INDEX_NAME = "index_stripe_events_on_event_id"

  def up
    execute("DELETE FROM stripe_events")

    change_column_null :stripe_events, :event_id, false
    change_column_null :stripe_events, :event_type, false

    remove_index :stripe_events, name: INDEX_NAME if index_name_exists?(:stripe_events, INDEX_NAME)

    add_index :stripe_events, :event_id, unique: true, name: INDEX_NAME unless index_exists?(:stripe_events, :event_id, unique: true, name: INDEX_NAME)
  end

  def down
    remove_index :stripe_events, name: INDEX_NAME if index_name_exists?(:stripe_events, INDEX_NAME)
    change_column_null :stripe_events, :event_type, true
    change_column_null :stripe_events, :event_id, true
  end
end