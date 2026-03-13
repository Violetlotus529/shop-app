# db/seeds.rb

puts "== Seeding started =="

# ----------------------------
# Admin User
# ----------------------------
admin = AdminUser.find_or_create_by!(email: "admin@test.com") do |u|
  u.password = "password"
  u.password_confirmation = "password"
end

# ----------------------------
# Customer
# ----------------------------
customer = Customer.find_or_create_by!(email: "user@test.com") do |u|
  u.password = "password"
  u.password_confirmation = "password"
  u.name = "Test Customer"
  u.postal_code = "510-0001"
  u.prefecture = "Mie"
  u.city = "Yokkaichi"
  u.address_line1 = "1-2-3 Example"
  u.address_line2 = "Sample Mansion 101"
  u.phone_number = "09012345678"
end

# ----------------------------
# Products + Variants
# ----------------------------
product_definitions = [
  {
    name: "Basic T-Shirt",
    description: "A simple everyday T-shirt.",
    category: "tops",
    price_cents: 2980,
    published: true,
    deleted: false,
    variants: [
      { color: "BLACK", size: "S", sku: "BTS-BLK-S", stock: 10, deleted: false },
      { color: "BLACK", size: "M", sku: "BTS-BLK-M", stock: 8, deleted: false },
      { color: "WHITE", size: "M", sku: "BTS-WHT-M", stock: 5, deleted: false }
    ]
  },
  {
    name: "Oversize Hoodie",
    description: "Relaxed silhouette hoodie.",
    category: "tops",
    price_cents: 6980,
    published: true,
    deleted: false,
    variants: [
      { color: "BLACK", size: "M", sku: "OVH-BLK-M", stock: 6, deleted: false },
      { color: "BLACK", size: "L", sku: "OVH-BLK-L", stock: 3, deleted: false },
      { color: "GRAY", size: "L", sku: "OVH-GRY-L", stock: 0, deleted: false }
    ]
  },
  {
    name: "Classic Denim",
    description: "Straight-fit denim pants.",
    category: "bottoms",
    price_cents: 9800,
    published: true,
    deleted: false,
    variants: [
      { color: "INDIGO", size: "M", sku: "CLD-IND-M", stock: 4, deleted: false },
      { color: "INDIGO", size: "L", sku: "CLD-IND-L", stock: 2, deleted: false }
    ]
  },
  {
    name: "Nylon Jacket",
    description: "Lightweight outerwear.",
    category: "outer",
    price_cents: 12800,
    published: true,
    deleted: false,
    variants: [
      { color: "BLACK", size: "M", sku: "NYJ-BLK-M", stock: 7, deleted: false },
      { color: "OLIVE", size: "L", sku: "NYJ-OLV-L", stock: 2, deleted: false }
    ]
  },
  {
    name: "Minimal Shoulder Bag",
    description: "Compact daily-use bag.",
    category: "bag",
    price_cents: 5400,
    published: true,
    deleted: false,
    variants: [
      { color: "BLACK", size: "FREE", sku: "MSB-BLK-F", stock: 9, deleted: false },
      { color: "BEIGE", size: "FREE", sku: "MSB-BEG-F", stock: 1, deleted: false }
    ]
  },
  {
    name: "Leather Key Case",
    description: "Small leather goods item.",
    category: "goods",
    price_cents: 3200,
    published: false,
    deleted: false,
    variants: [
      { color: "BLACK", size: "FREE", sku: "LKC-BLK-F", stock: 5, deleted: false }
    ]
  },
  {
    name: "Archive Sample Tee",
    description: "Archived product for trash demo.",
    category: "tops",
    price_cents: 2500,
    published: true,
    deleted: true,
    variants: [
      { color: "WHITE", size: "M", sku: "AST-WHT-M", stock: 0, deleted: false }
    ]
  }
]

products = {}

product_definitions.each do |attrs|
  variant_defs = attrs.delete(:variants)

  product = Product.find_or_initialize_by(name: attrs[:name])
  product.assign_attributes(attrs)
  product.save!

  variant_defs.each do |v_attrs|
    variant = product.product_variants.find_or_initialize_by(sku: v_attrs[:sku])
    variant.assign_attributes(v_attrs)
    variant.save!
  end

  products[product.name] = product
end

# ----------------------------
# Orders + OrderItems
# ----------------------------
basic_tshirt_variant = ProductVariant.find_by!(sku: "BTS-BLK-M")
hoodie_variant       = ProductVariant.find_by!(sku: "OVH-BLK-L")
denim_variant        = ProductVariant.find_by!(sku: "CLD-IND-M")
jacket_variant       = ProductVariant.find_by!(sku: "NYJ-BLK-M")

orders_data = [
  {
    code: "guest_paid",
    customer: nil,
    customer_name: "Guest User",
    customer_email: "guest1@example.com",
    postal_code: "510-0002",
    prefecture: "Mie",
    city: "Yokkaichi",
    address_line1: "2-2-2 Demo",
    address_line2: "Guest Residence 201",
    status: :paid,
    paid_at: Time.current,
    stripe_checkout_session_id: "cs_demo_guest_paid",
    stripe_payment_intent_id: "pi_demo_guest_paid",
    items: [
      { variant: basic_tshirt_variant, quantity: 2 }
    ]
  },
  {
    code: "registered_processing",
    customer: customer,
    customer_name: "Test Customer",
    customer_email: "user@test.com",
    postal_code: "510-0001",
    prefecture: "Mie",
    city: "Yokkaichi",
    address_line1: "1-2-3 Example",
    address_line2: "Sample Mansion 101",
    status: :processing,
    paid_at: 1.day.ago,
    stripe_checkout_session_id: "cs_demo_registered_processing",
    stripe_payment_intent_id: "pi_demo_registered_processing",
    items: [
      { variant: hoodie_variant, quantity: 1 },
      { variant: denim_variant, quantity: 1 }
    ]
  },
  {
    code: "guest_shipped",
    customer: nil,
    customer_name: "Tanaka Taro",
    customer_email: "guest2@example.com",
    postal_code: "510-0003",
    prefecture: "Mie",
    city: "Yokkaichi",
    address_line1: "3-3-3 Sample",
    address_line2: "Building A 303",
    status: :shipped,
    paid_at: 2.days.ago,
    stripe_checkout_session_id: "cs_demo_guest_shipped",
    stripe_payment_intent_id: "pi_demo_guest_shipped",
    items: [
      { variant: jacket_variant, quantity: 1 }
    ]
  },
  {
    code: "registered_completed",
    customer: customer,
    customer_name: "Test Customer",
    customer_email: "user@test.com",
    postal_code: "510-0001",
    prefecture: "Mie",
    city: "Yokkaichi",
    address_line1: "1-2-3 Example",
    address_line2: "Sample Mansion 101",
    status: :completed,
    paid_at: 3.days.ago,
    stripe_checkout_session_id: "cs_demo_registered_completed",
    stripe_payment_intent_id: "pi_demo_registered_completed",
    items: [
      { variant: basic_tshirt_variant, quantity: 1 },
      { variant: denim_variant, quantity: 2 }
    ]
  },
  {
    code: "guest_canceled",
    customer: nil,
    customer_name: "Suzuki Hanako",
    customer_email: "guest3@example.com",
    postal_code: "510-0005",
    prefecture: "Mie",
    city: "Yokkaichi",
    address_line1: "5-5-5 Cancel",
    address_line2: "Room 505",
    status: :canceled,
    paid_at: 1.day.ago,
    stripe_checkout_session_id: "cs_demo_guest_canceled",
    stripe_payment_intent_id: "pi_demo_guest_canceled",
    items: [
      { variant: hoodie_variant, quantity: 1 }
    ]
  }
]

orders_data.each do |data|
  items = data.delete(:items)
  code  = data.delete(:code)

  total_cents = items.sum do |item|
    item[:variant].product.price_cents * item[:quantity]
  end

  order = Order.find_or_initialize_by(
    stripe_checkout_session_id: data[:stripe_checkout_session_id]
  )

  order.assign_attributes(data.merge(total_cents: total_cents))
  order.save!

  order.order_items.destroy_all

  items.each do |item|
    unit_price_cents = item[:variant].product.price_cents
    quantity = item[:quantity]
    subtotal_cents = unit_price_cents * quantity

    OrderItem.create!(
      order: order,
      product_variant: item[:variant],
      quantity: quantity,
      unit_price_cents: unit_price_cents,
      subtotal_cents: subtotal_cents
    )
  end
end

# ----------------------------
# Stripe Event
# ----------------------------
StripeEvent.find_or_create_by!(event_id: "evt_demo_checkout_completed") do |e|
  e.event_type = "checkout.session.completed"
  e.processed_at = Time.current
  e.retry_count = 0
  e.last_error = nil
  e.last_attempted_at = Time.current
end

puts "== Seeding finished =="