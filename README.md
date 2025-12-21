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
  users {
    id                  uuid
    email               string
    password_digest     string
    full_name           string
    phone               string
    default_address_id  uuid
    created_at/update   datetime
  }
