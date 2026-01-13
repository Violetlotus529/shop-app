# VioletLotus EC Admin

## 1. Overview
- A single-store e-commerce application built with Ruby on Rails.
- 単一店舗のアパレルEC向け管理画面付きアプリケーション。
- Demo ----url

## 2. Design

### 2-1. Target Users
- Admin: store owner / inventory staff (single role)
- Customer: guest checkout or registered user

### 2-2. Checkout & Payment
- Cart-based checkout
- Payment: Stripe Checkout
- Currency: JPY, tax-inclusive pricing
- Shipping fee: fixed amount

### 2-3. Guest vs Registered Checkout
- Guest checkout: allowed, but address is required at checkout
- Registered user: address is collected at sign-up and reused at checkout

### 2-4. Product Variants
- Variant dimensions: color / size
- Stock is managed per variant (SKU-level)

### 2-5. 管理画面の設計方針
目的・想定
- 単一店舗で運用するアパレルECサイトを想定する。管理画面の利用者は店主・在庫管理スタッフで、商品管理 / 在庫管理 / 注文管理を行う。
- ユーザー画面の利用者は顧客で、商品の閲覧・購入を行う（ゲスト購入も可）。
- フレーム幅 1440px を前提に設計する。判断・条件分岐・画面遷移が多い 管理画面を優先して設計した。

画面と責務の分離（一覧 / 詳細 / 編集）
- 一覧：探索・把握・絞り込み・並び替え・対象選択・詳細への遷移を担う。
- 詳細/編集：更新・削除（論理削除）・復元などの 破壊的操作を集約する。
- 誤操作防止のため、一覧からは原則として破壊的操作を行わず、操作可能箇所を限定する。

在庫管理
- カラー・サイズを区別するため、在庫は バリアント（SKU）単位で管理する。
- 操作工数削減のため、編集ページは作らず 一覧内の「編集モード」ON/OFFで在庫数を更新する。
- 画面遷移やヘッダー操作時に未保存の変更がある場合は検知し、保存確認モーダルを表示する。
- 優先順位：保存確認モーダル > フィルターモーダル
- 自動保存はUX向上の側面もあるが、在庫・注文といった業務上の重要度が高い操作においては誤更新のリスクを避けるため、明示的な保存操作を優先した。
- 一覧での探索補助として、検索・フィルター・並び替えを実装する。

注文管理
- 注文一覧は 未処理 / 処理済み をスイッチで切り替えて表示する（どちらか一方のみ表示）。
- 誤操作防止のため、ステータス更新は 注文詳細のみで行う。
- 「処理中 / 発送済み / 配送完了 / キャンセル・返金」の遷移条件を定義し、不可逆の遷移ルールを保証する。
- 発送済み以降はキャンセル不可のため、発送済みに更新する際は警告（フラッシュ表示）を出す。

商品管理
- 誤操作防止のため、削除（論理削除）は 商品編集画面のみで可能とする。
- 在庫・注文履歴への影響防止のため、物理削除ではなく 論理削除（soft delete）+ 復元を採用する。
- ゴミ箱画面での探索補助として、検索・並び替えを実装する。
- 完全削除は行わない（管理UIとして提供しない）。

決済・在庫反映
- 外部決済として Stripe Checkout を採用する。
- 支払い確定は Webhook で受け取り、支払い確定後に在庫を減算する。
- 在庫が 0 の場合、ユーザー側のバリアント選択UIで SOLD OUT を自動表示する。

ドキュメント方針
- README：全体方針（設計思想 / 主要ルール / 仕様の要点）
- docs/：詳細（API設計 / 画面仕様 / 状態遷移)

### Order Status Flow
- Orders move forward-only through their lifecycle (e.g. `paid -> shipped -> completed`).
- `canceled` is allowed only before shipping; after `shipped` cancellation is blocked.
- Detailed state transition rules are documented in `docs/30-state-machines.md`.

## 3. Domain Rules
### 3-1. Order Status State Machine
pending → paid → processing → shipped → completed
processing → canceled

制約:
- shipped 以降は canceled 不可
- ステータス更新は「管理画面の注文詳細」でのみ可能
- canceled は pending / paid / processing でのみ可能
- 不正なステータス遷移は API 側で拒否する

### 3-2. Order Status & Transitions
利用ステータス:
- pending
- paid
- processing
- shipped
- completed
- canceled

遷移フロー:
- pending → paid        （Stripe 決済）
- paid → processing     （バックエンドで自動）
- processing → shipped  （管理画面）
- shipped → completed   （管理画面）
- processing → canceled （管理画面）

禁止される遷移:
- shipped / completed から canceled への変更
- completed から processing / shipped への巻き戻し
- pending / paid / processing 以外から canceled へ遷移

### 3-3. Inventory Constraints
- stock >= 0 (負の値不可)
- 在庫変更は管理画面の編集モードのみ
- 支払い確定(Webhook)後に在庫減算
- 在庫0 の場合は SOLD OUT 表示 (ユーザー側)

### 3-4. Product State
active -> deleted
deleted -> active (復元可能)

制約:
- 論理削除のため物理削除は行わない
- deleted 状態の商品は一覧の "ゴミ箱" に表示
- 編集操作は active のみ許可

## 4. API Overview
### 4-1. API Common Rules
- ALL timestamps are **IS08601** format.
- `Authorization: Bearer <token>` is required for all admin APIs except login/reset.
- Error response structure:
```json
{
  "error": "ERROR_CODE",
  "message": "人間向けの説明"
}
```
- Pagination format:
```json
{
  "current": 1,
  "total_pages": 3
}
```

### 4-2. Endpoint List
### 4-2. Endpoint List

| Group      | Method | Path                             | Summary                     |
|-----------|--------|----------------------------------|-----------------------------|
| Auth      | POST   | /admin/login                    | 管理者ログイン              |
| Auth      | POST   | /admin/logout                   | ログアウト                  |
| Auth      | POST   | /admin/password/forgot          | パスワード再設定メール送信  |
| Auth      | POST   | /admin/password/reset           | パスワード再設定            |
| Products  | GET    | /admin/products                 | 商品一覧                     |
| Products  | GET    | /admin/products/:id             | 商品詳細（編集/プレビュー） |
| Products  | POST   | /admin/products                 | 商品作成                     |
| Products  | PUT    | /admin/products/:id             | 商品更新                     |
| Products  | PATCH  | /admin/products/:id/deleted     | 削除・復元トグル            |
| Trash     | GET    | /admin/trash/products           | 削除済み商品一覧             |
| Trash     | GET    | /admin/trash/products/:id       | 削除済み商品詳細             |
| Orders    | GET    | /admin/orders                   | 注文一覧                     |
| Orders    | GET    | /admin/orders/:id               | 注文詳細                     |
| Orders    | PATCH  | /admin/orders/:id/status        | 注文ステータス更新          |
| Inventory | GET    | /admin/inventories              | 在庫一覧（SKU単位）          |
| Inventory | PUT    | /admin/inventories              | 在庫一括更新                 |

## 5. API Details
### 5-1. Auth APIs
#### POST /admin/login
概要:
- 管理者のログインを行う。

認可:
- 認証不要

### Headers:
Content-Type: application/json

### Request Body (JSON):
```json
{
  "email": "admin@example.com",   // 管理者メールアドレス
  "password": "password123"       // パスワード
}
```
### Response 200:
```json
{
  "id": "admin-uuid",
  "email": "admin@example.com",
  "token": "jwt-or-session-token"
}
```
### Status Codes:
- 200 OK: ログイン成功
- 401 Unauthorized: 認証失敗(メール or パスワード不正)

#### POST /admin/logout
概要:
- 管理者のログアウトを行う。

認可:
- 管理者認証が必要(Authorizationヘッダーでトークンを送る)

### Headers:
Content-Type: application/json
Authorization: Bearer <token>

### Response 200:
```json
{
  "message": "ログアウトしました。"
}
```
### Status Codes:
- 200 OK: 成功
- 401 Unauthorized: トークンが無効・期限切れ

#### POST /admin/password/forgot
概要:
- パスワード再設定メールを送信する。

認可:
- 認証不要

### Headers:
Content-Type: application/json

### Request Bady（JSON）:
```json
{
  "email": "admin@example.com"  // 管理者メールアドレス
}
```
### Response 200:
```json
{
  "message": "パスワード再設定メールを送信しました。"
}
```
### Status Codes:
- 200 OK: 成功
- 404 NOT FOUND: メールアドレスが存在しない

#### POST /admin/password/reset
概要:
- パスワード再設定を行う。

認可:
- 認証不要(reset_token の検証で代替)

### Headers:
Content-Type: application/json

### Request Bady(JSON):
```json
{
  "token": "abcdef123456"  //resetメールに含めたトークン
  "password": "newPassword123"  //新しいパスワード
}
```
### Response 200:
```json
{
  "message": "パスワードを更新しました。"
}
```
### Status Codes:
- 200 OK: 成功
- 400 Bad Request: 入力値が不足または不正
- 404 Not Found: リソースが存在しない
- 422 Unprocessable Entity: バリデーション違反

### 失敗レスポンス例(404 Not Found):
```json
{
  "error": "INVALID_TOKEN",
  "message": "パスワード再設定リンクが無効または期限切れです。"
}
```
### 5-2. Product APIs
#### GET /admin/products
概要:
- 商品一覧を取得する(検索・フィルタ・並び替え・含む)

認可:
- 管理者認証が必要。

### Headers: 
Content-Type: application/json
Authorization: Bearer <token>

### Query Parameters:
 パラメータ  | 型     | 必須 | 説明 |
-----------|--------|-----|------|
 `q`      | string | 任意 | 商品名・説明の部分一致検索  |
 `status` | string | 任意 | all / published / unpublished |
 `sort`   | string | 任意 | updated_at_desc / updated_at_asc |
 `page`   | number | 任意 | ページ番号（１以上の整数）|

### Response 200:
```json
{
  "products": [
    {
      "id": "product-uuid",
      "name": "Tシャツ",
      "price": 2980,
      "thumbnail_url": "/images/products/xxx.jpg",
      "published": true,
      "update_at": "2026-01-10T12:34:56Z"
    }
  ],
  "pagination": {
    "current": 1,
    "total_pages": 3
  }
}
```
### Status Codes:
- 200 OK: 成功
- 400 : 不正なクエリパラメータ
- 401 Unauthorized: 認証トークンが無効 or 未提供

#### GET /admin/products/:id
概要:
- 商品の詳細を取得する（編集画面・プレビュー用）。

認可:
- 管理者認証が必要。

### Headers:
- Authorization: Bearer <token>

### Path Parameters:
 パラメータ | 型     | 必須 | 説明         |
 --------|--------|-----|--------------|
 id      | string | 必須 | 商品ID(UUID) |

### Response 200:
```json
{
  "id": "product-uuid",
  "name": "Tシャツ",
  "description": "商品説明テキスト",
  "category": "tops",
  "price": 2980,
  "image_url":  "/image/xxx.jpg",
  "published": true,
  "variants": [
    { "id": "variant-uuid-1", "color": "BLACK", "size": "M", "sku": "TSHIRT-BLK-M" }
  ]
}
```
### Status Codes:
- 200 OK: 成功
- 401 Unauthorized: 無効なトークン・未提供
- 404 Not Found: 指定されたIDの商品が存在しない

#### POST /admin/products
概要:
- 商品を新規作成する。

認可:
- 管理者認証が必要。

### Headers:
Content-Type: application/json
Authorization: Bearer <token>

### Request Body(JSON):
```json
{
  "name": "Tシャツ",
  "description": "商品説明テキスト",
  "category": "tops",
  "price": 2980,
  "image": "file-id-or-base64"
}
```
### Response 201:
```json
{
  "id": "product-uuid",
  "message": "商品を作成しました。"
}
```
### Status Codes:
- 201 Created: 作成成功
- 400 Bad Request: 必須項目不足・形式不正
- 401 Unauthorized: 認証トークンが無効 or 未提供
- 422 Unprocessable Entity: バリデーションエラー


#### PUT /admin/products/:id
概要:
- 商品本体・基本情報・バリアントをまとめて編集する。

認可:
- 管理者認証が必要。

### Headers:
Content-Type: application/json
Authorization: Bearer <token>

### Path Parameters:
 パラメータ  | 型    | 必須   | 説明          |
 ---------|-------|-------|--------------|
  id      | string | 必須 | 商品ID（UUID） |

### Request Body (JSON):
```json
{
  "name": "Tシャツ",
  "description": "商品説明テキスト",
  "category": "tops",
  "price": 2980,
  "image": "file-id-or-base64",
  "published": true,
  "variants": [
    {
      "id": "variant-uuid-1",
      "color": "BLACK",
      "size": "M",
      "sku": "TSHIRTS-BLK-S"
    },
    {
      "id": "variant-uuid-2",
      "color": "WHITE",
      "size": "L",
      "sku": "TSHIRT-BLK-M"
    }
  ]
}

```
### Response 200:
```json
{
  "id": "product-uuid",
  "message": "商品を更新しました。"
}
```
### Status Codes:
- 200 OK: 正常に更新された
- 400 Bad Request: JSON形成不正・必須項目不足
- 401 Unauthorized: 認証トークンが無効・未提供
- 404 Not Found: 指定されたIDの商品が存在しない
- 422 Unprocessable Entity: バリデーションエラー（価格が負数など）

#### PATCH /admin/products/:id/deleted
概要:
- 商品の論理削除フラグをON/OFFする（削除・復元トグリ）。
- どの画面から呼んでも「deleted を true/false にするだけ」。

認可:
- 管理者認証が必要

### Headers:
- Content-Type: application/json
- Authorization: Bearer <token>

### Path Parameters:
 パラメータ  | 型     | 必須  | 説明         |
 ---------|--------|------|--------------|
 id       | string | 必須 | 商品ID（UUID） |

### Request Bady(JSON):
```json
{
  "deleted": true   //削除する場合は true, 復元する場合は false
}
```
### Response 200:
```json
{
  "id": "product-uuid",
  "message": "商品を削除しました。"
}
```
### Status Codes:
- 200 OK: 正常に更新された
- 400 Bad Request: JSON形式不正・必須項目不足
- 401 Unauthorized: 認証トークンが無効 or 未提供
- 404 Not Found: 指定されたIDの商品が存在しない

#### GET /admin/trash/products
概要:
- `deleted = true` の商品だけを一覧取得する（検索・並び替えを含む）。

認可:
- 管理者認証が必要。

### Headers:
Authorization: Bearer <token>

### Query Parameters:
 パラメータ | 型     | 必須 | 説明                              |
 --------|--------|------|-----------------------------------|
 q       | string | 任意 | 商品名での一部一致検索               |
 sort    | string | 任意 | deleted_at_desc / deleted_at_asc |
 page    | number | 任意 | ページ番号(１以上の整数)             |

### Response 200:
```json
{
  "products": [
    {
      "id": "uuid-1",
      "name": "Tシャツ",
      "published": true,
      "deleted_at": "2026-01-10T12:34:56Z"
    }
  ],
  "pagination": {
    "current_page": 1,
    "total_pages": 3
  }
}
```
### Status Codes:
- 200 OK: 成功
- 401 Unauthorized: トークンが無効・未提供
- 404 Not Found: ページ範囲外もしくは該当商品が存在しない

#### GET /admin/trash/products/:id
概要:
- `deleted = true` の商品詳細を取得する。
- `deleted = false`（すでに削除済み）の場合も 404 を返す。

認可:
- 管理者認証が必要

### Headers:
- Authorization: Bearer <token>

### Path Parameters:
 パラメータ  | 型     | 必須 | 説明         |
 ---------|--------|-----|--------------|
 id       | string | 必須 | 商品ID(UUID) |

### Response 200:
```json
{
  "id": "product-uuid-1",
  "name": "Tシャツ",
  "description": "商品説明テキスト",
  "category": "tops",
  "price": 2980,
  "image_url": "/images/xxx.jpg",
  "deleted": true,
  "deleted_at": "2026-01-10T12:34:56Z",
  "variants": [
    { "variant_id": "v1", "color": "BLK", "size": "S", "stock": 10 },
    { "variant_id": "v2", "color": "WHT", "size": "M", "stock": 5 }
  ]
}
```
### Status Codes:
- 200 OK: 成功
- 401 Unauthorized: トークンが無効・未提供
- 404 Not Found: 対象IDが存在しない、または削除されていない

### 5-3. Order APIs
#### GET /admin/orders
概要:
- 注文一覧を取得する（検索、フィルター、並び替えを含む）。

認可:
- 管理者認証が必要。

### Headers:
- Authorization: Bearer <token>

### Query Parameters:
 パラメータ     | 型 | 必須    | 説明                                |
 ------------|----|---------|------------------------------------|
 q           | string | 任意　 　| 注文番号、顧客名、メールアドレスでの一部一致検索 |
 status      | string | 任意    | pending / paid / processing / shipped / completed / canceled |
 from        | string | 任意    | 開始日（YYYY-MM-DD）                 |
 to          | string | 任意    | 終了日（YYYY-MM-DD）                 |
 sort        | string | 任意    | created_at_desc　/ created_at_asc（注文日時の降順/昇順）　|
 page        | number | 任意    | ページ番号（１以上の整数）              |
 
### Response 200:
```json
{
  "orders": [
    {
      "id": "order-uuid",
      "order_number": "20260110-001",
      "created_at": "2026-01-10T12:34:56Z",
      "customer_type": "guest",
      "customer_email": "user@example.com",
      "customer_name": "Tanaka Taro",
      "status": "paid",
      "payment_method": "credit",
      "item_count": 2,
      "total_amount": 2980,
    }
  ],
  "pagination": {
    "current": 1,
    "total_pages": 3
  }
}
```
### Status Codes:
- 200 OK: 成功
- 401 Unauthorized: トークンが無効 or 未提供

#### GET /admin/orders/:id
概要:
- 注文の詳細を取得する（注文情報＋注文に含まれる商品一覧）。

認可:
- 管理者認証が必要。

### Headers:
- Authorization: Bearer <token>

### Path Parameters:
 パラメータ  | 型     | 必須 |  説明         |
 ---------|--------|------|---------------|
 id       | string | 必須 | 注文ID（UUID） |
### Response 200:
```json
{
  "id": "order-uuid",
  "order_number": "20260110-001",

  "status": "processing",
  "payment_method": "credit",
  "total_amount": 2980,
  "item_count": 2,

  "created_at": "2026-01-10T12:34:56Z",
  "paid_at": "2026-01-10T12:34:56Z",
  "shipped_at": null,
  "completed_at": null,
  "canceled_at": null,

  "customer": {
    "type": "guest",
    "name": "Tanaka Taro",
    "email": "user@example.com",
    "postal_code": "XX県",
    "prefecture": "XX市",
    "city": "XX町",
    "address_line1": "XXX-XX",
    "address_line2": "XXXマンション XXX"
  },

  "order_items": [
    {
      "product_id": "product-uuid-1",
      "product_name": "Tシャツ",
      "color": "BLK",
      "size": "S",
      "quantity": 2,
      "unit_price": 1490,
      "subtotal": 2980
    }
  ]
}
```
### Status Codes:
- 200 OK: 成功
- 401 Unauthorized: トークンが無効・未提供
- 404 Not Found: 指定されたIDの注文が存在しない

#### PATCH /admin/orders/:id/status
概要:
- 注文ステータスを更新する。
- Order Status & Transitions に定義されたルールに従い、不正な遷移は拒否する。

認可:
- 管理者認証が必要。

### Headers:
- Content-Type: application/json
- Authorization: Bearer <token>

### Request Body (Json):
```json
{
  "status": "shipped"
}
```
### Response 200:
```json
{
  "id": "order-uuid",
  "message": "ステータスを更新しました。"
}
```
### Status Codes:
- 200 OK: 正常に更新された
- 400 Bad Request: statusが欠落・定義外の値
- 401 Unauthorized: トークンが無効・未提供
- 404 Not Found: 注文が存在しない
- 422 Unprocessable Entity:
- Order Status & Transitions に反する遷移を要求した場合
- 例: shipped/completed の注文に "canceled"を指定した場合

### 5-4. Inventory APIs
#### GET /admin/inventories
概要:
- バリアント（SKU）単位の在庫一覧を取得する（検索・フィルター・並び替えを含む）。

認可:
- 管理者認証が必要。

### Headers:
- Authorization: Bearer <token>

### Query Parameters:
 パラメータ     | 型     | 必須  | 説明                                             |
 ------------|--------|------|--------------------------------------------------|
 q           | string | 任意 | 商品名 / カラー / サイズの部分一致検索                 |
 stock_state | string | 任意 | all / in_stock / low / out_of_stock              |
 sort        | string | 任意 | stock_desc / stock_asc(在庫数の降順/昇順)           |
 page        | number | 任意 | ページ番号（１以上の整数）                            |

### Response 200:
```json
{
  "variants": [
    {
      "id": "variant-uuid",
      "product_name": "Tシャツ",
      "color": "BLK",
      "size": "S",
      "stock": 10,
      "updated_at": "2026-01-10T12:34:56Z",
    }
  ],
  "pagination": {
    "current_page": 1,
    "total_pages": 3
  }
}
```
### Status Codes:
- 200 OK: 成功
- 401 Unauthorized: トークンが無効・未提供

#### PUT /admin/inventories
概要:
- 編集モード ON 中に変更された全ての在庫を一括更新する。

認可:
- 管理者認証が必要

### Headers:
- Content-Type: application/json
- Authorization: Bearer <token>

### Request Body (JSON):
```json
{
  "updates": [
    {
      "id": "variant-uuid-1",
      "stock": 15
    },
    {
      "id": "variant-uuid-2",
      "stock": 0
    }
  ]
}
```
### Response 200:
```json
{
  "updated_count": 2,
  "message": "在庫を更新しました。"
}
```
### Status Codes:
- 200 OK: 正常に更新された
- 400 Bad Request: JSON形式が不正
- 401 Unauthorized: トークン無効・未提供
- 422 Unprocessable Entity: 在庫数が負数などのバリデーション違反

### 5-5. Error Codes:
- BAD_REQUEST            / JSONフォーマット不正、クエリ不正
- UNAUTHORIZED           / トークンが無効 or 未提供
- INVALID_CREDENTIALS    / ログイン失敗
- INVALID_TOKEN          / パスワードリセットなどの token 不正
- NOT_FOUND              / リソースが存在しない
- VALIDATION_ERROR       / バリデーション違反
- CONFLICT               / 整合性エラー・復元不可など

## 6. Setup
### 6-1. Tech Stack
- Ruby 3.2.2
- Ruby on Rails 7.1
- PostgreSQL
- CSS / JavaScript
- Render (deployment)

### 6-2. Local Setup
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

    
