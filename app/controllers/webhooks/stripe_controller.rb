class Webhooks::StripeController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    payload = request.raw_post
    sig     = request.env["HTTP_STRIPE_SIGNATURE"]
    secret  = ENV.fetch("STRIPE_WEBHOOK_SECRET")

    event = Stripe::Webhook.construct_event(payload, sig, secret)

    se = StripeEvent.find_or_initialize_by(event_id: event.id)
    se.event_type = event.type
    se.last_attempted_at = Time.current

    # 既に処理済みならログだけ残してOK返す
    if se.processed_at.present?
      se.save! if se.changed?
      head :ok
      return
    end

    se.save!

    case event.type
    when "checkout.session.completed"
      handle_checkout_completed(event.data.object, se)  # ★seを渡す
    end

    head :ok

  rescue JSON::ParserError, Stripe::SignatureVerificationError
    head :bad_request
  rescue => e
    if defined?(se) && se.present?
      se.increment!(:retry_count)
      se.update!(
        last_error: e.message,
        last_attempted_at: Time.current
      )
    end

    Rails.logger.error("[webhook] #{e.class}: #{e.message}")
    Rails.logger.error(e.backtrace.first(10).join("\n"))

    head :internal_server_error
  end

  private

  def handle_checkout_completed(session_obj, se)  # ★seを受け取る
    order_id = session_obj.metadata&.[]("order_id")
    return if order_id.blank?

    order = Order.find_by(id: order_id)
    return if order.nil?

    order.with_lock do
      return if order.paid? || order.failed? || order.refunded?

      Order.transaction do
        qty_by_variant_id =
          order.order_items
               .group_by(&:product_variant_id)
               .transform_values { |items| items.sum(&:quantity) }

        variant_ids = qty_by_variant_id.keys.sort
        variants = ProductVariant.lock.where(id: variant_ids).index_by(&:id)

        variant_ids.each do |vid|
          v = variants.fetch(vid)
          required = qty_by_variant_id.fetch(vid)
          raise "stock shortage" if v.stock < required
        end

        variant_ids.each do |vid|
          v = variants.fetch(vid)
          required = qty_by_variant_id.fetch(vid)
          v.update!(stock: v.stock - required)
        end

        order.update!(
          status: :paid,
          paid_at: Time.current,
          stripe_payment_intent_id: session_obj.payment_intent
        )

        order.customer.cart_items.destroy_all if order.customer_id.present?
      end

      se.update!(processed_at: Time.current, last_error: nil)
    end

  rescue => e
    if e.message == "stock shortage"
      payment_intent = session_obj.payment_intent
      if payment_intent.present? && order.stripe_refund_id.blank?
        refund = Stripe::Refund.create(
          { payment_intent: payment_intent },
          { idempotency_key: "refund:order#{order.id}" }
        )
        order.update!(
          status: :refunded,
          refunded_at: Time.current,
          stripe_refund_id: refund.id
        )
      else
        order.update!(status: :failed) unless order.paid?
      end

      se.update!(processed_at: Time.current, last_error: nil)
      return
    end

    Rails.logger.error("[webhook] failed: #{e.class} #{e.message}")
    order.update!(status: :failed) if !order.paid? && !order.refunded?
    raise
  end
end