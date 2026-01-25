class AddUniqIndexToStripeEvents < ActiveRecord::Migration[7.1]
  def change
    change_column_null :stripe_events, :event_id, false
    change_column_null :stripe_events, :event_type, false
    add_index :stripe_events, :event_id, unique: true
  end
end
