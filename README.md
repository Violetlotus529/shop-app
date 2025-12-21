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
