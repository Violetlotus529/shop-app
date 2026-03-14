class AddUniqIndexToStripeEvents < ActiveRecord::Migration[7.1]
  def up
    execute("DELETE FROM stripe_events")

    change_column_null :stripe_events, :event_id, false
    change_column_null :stripe_events, :event_type, false
    add_index :stripe_events, :event_id, unique: true
  end

  def down
    remove_index :stripe_events, :event_id if index_exists?(:stripe_events, :event_id)
    change_column_null :stripe_events, :event_type, true
    change_column_null :stripe_events, :event_id, true
  end
end