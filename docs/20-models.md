# Models

## Product
- has_many :product_variants
- fields :name, description, price_cents, published, deleted

## ProductVariant
- belongs_to :product
- fields: sku, color, size, stock