class EnforceStripeEventsConstraints < ActiveRecord::Migration[7.1]
  def up
    # 先にNULLを埋める（今は空でも安全）
    execute "UPDATE stripe_events SET event_id = '' WHERE event_id IS NULL"
    execute "UPDATE stripe_events SET event_type = '' WHERE event_type IS NULL"

    # NOT NULL 制約
    execute "ALTER TABLE stripe_events ALTER COLUMN event_id SET NOT NULL"
    execute "ALTER TABLE stripe_events ALTER COLUMN event_type SET NOT NULL"

    # UNIQUE INDEX（既にあればスキップ）
    execute "CREATE UNIQUE INDEX IF NOT EXISTS index_stripe_events_on_event_id ON stripe_events (event_id)"
  end

  def down
    execute "DROP INDEX IF EXISTS index_stripe_events_on_event_id"
    execute "ALTER TABLE stripe_events ALTER COLUMN event_id DROP NOT NULL"
    execute "ALTER TABLE stripe_events ALTER COLUMN event_type DROP NOT NULL"
  end
end
