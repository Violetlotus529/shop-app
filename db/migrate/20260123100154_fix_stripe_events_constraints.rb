class FixStripeEventsConstraints < ActiveRecord::Migration[7.1]
  def up
    # 既存データがあると null制約で落ちるので保険（今は空でもOK）
    execute "UPDATE stripe_events SET event_id = '' WHERE event_id IS NULL"
    execute "UPDATE stripe_events SET event_type = '' WHERE event_type IS NULL"

    change_column_null :stripe_events, :event_id, false
    change_column_null :stripe_events, :event_type, false

    unless index_exists?(:stripe_events, :event_id, unique: true)
      add_index :stripe_events, :event_id, unique: true
    end
  end

  def down
    if index_exists?(:stripe_events, :event_id, unique: true)
      remove_index :stripe_events, :event_id
    end
    change_column_null :stripe_events, :event_id, true
    change_column_null :stripe_events, :event_type, true
  end
end
