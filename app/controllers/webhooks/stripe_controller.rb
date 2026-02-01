class Webhooks::StripeController < ApplicationController
  skip_before_action :verify_authenticity_token
  def create
    payload = request.raw_post
    sig = request.env["HTTP_STRIPE_SIGNATURE"]
    secret = ENV.fetch("STRIPE_WEBHOOK_SECRET")

    event = Stripe::Webhook.construct_event(payload, sig, secret)

    StripeEvent.find_or_create_by!(event_id: event.id) do |se|
      se.event_type = event.type
    end

    case event.type
    when "checkout.session.completed"
      handle_checkout_completed(event.data.object)
    end

    head :ok
  rescue JSON::ParserError, Stripe::SignatureVerificationError
    head :bad_request
  rescue => e
    Rails.logger.error("[webhook] #{e.class}: #{e.message}")
    Rails.logger.error(e.backtrace.first(10).join("\n"))
    head :internal_server_error
  end

  private

  def handle_checkout_completed(session_obj)
    order_id = session_obj.metadata&.[]("order_id")
    return if order_id.blank?

    order = Order.find_by(id: order_id)
    return if order.nil?

    order.with_lock do
      return if order.paid?

      ok = false

      begin
        Order.transaction do
          # 1) 在庫チェック（ロック）
          order.order_items.each do |item|
            v = ProductVariant.lock.find(item.product_variant_id)
            raise "stock shortage" if v.stock < item.quantity
          end

          # 2) 減算
          order.order_items.each do |item|
            v = ProductVariant.lock.find(item.product_variant_id)
            v.update!(stock: v.stock - item.quantity)
          end

          # 3) paid確定
          order.update!(
            status: :paid,
            paid_at: Time.current,
            stripe_payment_intent_id: session_obj.payment_intent
          )

          order.customer.cart_items.destroy_all if order.customer_id.present?
        end

        ok = true
      rescue => e
        Rails.logger.error("[webhook] checkout_completed failed: #{e.class} #{e.message}")
        ok = false
      end

      order.update!(status: :failed) unless ok
    end
  end
end
