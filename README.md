Demo：
# A single-store e-commerce application built with Ruby on Rails.

## Overview
This app is designed for a small apparel shop, allowing store staff to manage products,
variants (color/size), inventory, and orders, while customers can purchase items
with or without an account using Stripe Checkout.

## Design

### Target Users
- Admin: store owner / inventory staff (single role)
- Customer: guest checkout or registered user

### Checkout & Payment
- Cart-based checkout
- Payment: Stripe Checkout
- Currency: JPY, tax-inclusive pricing
- Shipping fee: fixed amount

### Guest vs Registered Checkout
- Guest checkout: allowed, but address is required at checkout
- Registered user: address is collected at sign-up and reused at checkout

### Product Variants
- Variant dimensions: color / size
- Stock is managed per variant (SKU-level)

### Inventory Update Policy
- Stock is decremented after payment confirmation via Stripe webhook
- If stock reaches 0, the UI displays SOLD OUT automatically

### Order Status Flow
- Forward-only transitions: `paid -> shipped -> completed`
- `canceled` is allowed only before shipping
  - allowed: before `shipped`
  - blocked: after `shipped` (default rule)

### Admin Policy
- Soft delete is used (logical deletion)
- Publish/unpublish is supported (visible control independent of deletion)
- Admin pages are isolated under `/admin` and require admin authentication

### API & Data Flow
- 
## Features
- 

## Tech Stack
- Ruby 3.2.2
- Ruby on Rails 7.1
- PostgreSQL
- CSS / JavaScript
- Render (deployment)

## Notes
- 

## Local Setup
```bash
bundle install
rails db:create db:migrate
rails s
```

## Detailed Setup
```bash
git clone <your-repo-url>
cd shop-app
bundle install
yarn install
rails db:create db:migrate
bin/dev
```
```mermaid
erDiagram
  USERS {
    uuid id PK
    string email
    string password_digest
    string full_name
    string phone
    boolean is_admin
    datetime created_at
    datetime updated_at
  }

  ADDRESSES {
    uuid id PK
    uuid user_id FK
    string postal_code
    string prefecture
    string city
    string address_line1
    string address_line2
    string phone
    boolean is_default
    datetime created_at
    datetime updated_at
  }

  PRODUCTS {
    uuid id PK
    string name
    text description
    integer price_cents
    boolean published
    boolean deleted
    datetime created_at
    datetime updated_at
  }

  PRODUCT_VARIANTS {
    uuid id PK
    uuid product_id FK
    string sku
    string color
    string size
    integer stock
    boolean deleted
    datetime created_at
    datetime updated_at
  }

  CARTS {
    uuid id PK
    uuid user_id FK
    string guest_token
    datetime created_at
    datetime updated_at
  }

  CART_ITEMS {
    uuid id PK
    uuid cart_id FK
    uuid product_variant_id FK
    integer quantity
    datetime created_at
    datetime updated_at
  }

  ORDERS {
    uuid id PK
    uuid user_id FK
    uuid address_id FK
    string email
    string full_name
    integer shipping_fee_cents
    integer total_cents
    string status
    datetime paid_at
    datetime shipped_at
    datetime completed_at
    datetime canceled_at
    datetime created_at
    datetime updated_at
  }

  ORDER_ITEMS {
    uuid id PK
    uuid order_id FK
    uuid product_variant_id FK
    integer unit_price_cents
    integer quantity
    integer subtotal_cents
    datetime created_at
    datetime updated_at
  }

  PAYMENTS {
    uuid id PK
    uuid order_id FK
    string provider
    string stripe_checkout_session_id
    string stripe_payment_intent_id
    integer amount_cents
    string status
    datetime paid_at
    datetime created_at
    datetime updated_at
  }

  USERS ||--o{ ADDRESSES : has
  USERS ||--o{ CARTS : has
  CARTS ||--o{ CART_ITEMS : contains
  PRODUCTS ||--o{ PRODUCT_VARIANTS : has
  PRODUCT_VARIANTS ||--o{ CART_ITEMS : in
  USERS ||--o{ ORDERS : places
  ADDRESSES ||--o{ ORDERS : used_for
  ORDERS ||--o{ ORDER_ITEMS : includes
  PRODUCT_VARIANTS ||--o{ ORDER_ITEMS : sold_as
  ORDERS ||--o{ PAYMENTS : paid_by

    
