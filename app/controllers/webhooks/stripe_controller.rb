class Webhooks::StripeController < ApplicationController
  skip_before_action :verify_authenticity_token
  def create
    payload = request.raw_post
    sig = request.env["HTTP_STRIPE_SIGNATURE"]
    secret = ENV.fetch("STRIPE_WEBHOOK_SECRET")

    event = Stripe::Webhook.construct_event(payload, sig, secret)

    return head :ok if StripeEvent.exists?(event_id: event.id)
    StripeEvent.create!(event_id: event.id, event_type: event.type)

    case event.type
    when "checkout.session.completed"
      handle_checkout_completed(event.data.object)
    end

    head :ok
  rescue JSON::ParserError, Stripe::SignatureVerificationError
    head :bad_request
  end

  private

  def handle_checkout_completed(session_obj)
    order_id = session_obj.metadata&.[]("order_id")
    return unless order_id.present?

    order = Order.find(order_id)
    return unless order
    return if order.paid?

    Order.transaction do
      order.order_items.each do |item|
        v = ProductVariant.lock.find(item.product_variant_id)
        if v.stock < item.quantity
          order.update!(status: :failed)
          return
        end
      end

      order.order_items.each do |item|
        v = ProductVariant.lock.find(item.product_variant_id)
        v.update!(stock: v.stock - item.quantity)
      end

      order.update!(
        status: :paid,
        paid_at: Time.current,
        stripe_payment_intent_id: session_obj.payment_intent
      )
    end
  end
end