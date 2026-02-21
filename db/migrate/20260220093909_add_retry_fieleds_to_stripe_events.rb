class AddRetryFieledsToStripeEvents < ActiveRecord::Migration[7.1]
  def change
    add_column :stripe_events, :last_error, :text
    add_column :stripe_events, :retry_count, :integer, default: 0, null: false
    add_column :stripe_events, :last_attempted_at, :datetime
  end
end
