class Webhooks::StripeController < ApplicationController
  skip_before_action :verify_authenticity_token
  def create
    payload = request.raw_post
    sig = request.env["HTTP_STRIPE_SIGNATURE"]
    secret = ENV.fetch("STRIPE_WEBHOOK_SECRET")

    event = Stripe::Webhook.construct_event(payload, sig, secret)

    se = StripeEvent.find_or_initialize_by(event_id: event.id)
    if se.persisted?
      head :ok
      return
    end
    se.event_type = event.type
    se.save!

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
      return if order.paid? || order.failed?

      begin
        Order.transaction do
          qty_by_variant_id =
            order.order_items
                 .group_by(&:product_variant_id)
                 .transform_values { |items| items.sum(&:quantity) }

          variant_ids = qty_by_variant_id.keys.sort

          variants = ProductVariant.lock.where(id: variant_ids).index_by(&:id)

          # 在庫チェック
          variant_ids.each do |vid|
            v = variants.fetch(vid)
            required = qty_by_variant_id.fetch(vid)
            raise "stock shortage" if v.stock < required
          end

          # 減算
          variant_ids.each do |vid|
            v = variants.fetch(vid)
            required = qty_by_variant_id.fetch(vid)
            v.update!(stock: v.stock - required)
          end

          # 3) paid確定
          order.update!(
            status: :paid,
            paid_at: Time.current,
            stripe_payment_intent_id: session_obj.payment_intent
          )

          order.customer.cart_items.destroy_all if order.customer_id.present?
        end

      rescue => e
        Rails.logger.error("[webhook] failed: #{e.class} #{e.message}")

        order.update!(status: :failed)
      end
    end
  end
end