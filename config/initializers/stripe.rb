Stripe.api_key = ENV["STRIPE_SECRET_KEY"]

if Stripe.api_key.blank?
  Rails.logger.warn("[stripe] STRIPE_SECRET_KEY is not set")
end