# Dev Notes

- 疑問点メモ
- 現在のタスク
- 次に整理すべき内容

- column(カラム)
データの項目

- index(インデックス)
検索を早くする仕組み

- unique
重複を禁止する制約 (例) unique: true

- マイグレーションファイルの役割
DBテーブルの構造を定義する
カラム名/型/制約（null false/unique/foreign key)を決める
「DB設計はマイグレーションから始まる」

- モデルファイルの役割
テーブルと 1:1で対応
関連（has_many/belongs_to）を定義する
バリデーションを定義する
ビジネスロック（計算・状態遷移）を書く場所

- referenceとは？
- migrate variant （t.reference :product）
- 外部キー用のカラム +インデックスをまとめて作成する型。t.reference :productはproduct内に複数のカラムがあるからこれが必要。

- null: falseがなぜ必要か？
- migrate
- そのカラムは空が絶対の許されないから（エラー起こす）
、検索とかは空でもいいからfalseがいらない

- foreign_keyとは？
- migrate（t.references :product, foreign_key: true）
- DB に「product_variants.product_id は products.idと一致しなければならない」という制約を作る。

- add_index :xxx, :yyyとは？
- migrate (add_index :product_variants, :sku, unique: true)
- 検索用インデックスを作る

- has_many とは？
- models > product
- 一つの商品(product)は複数のバリアントを持つ
※モデル同士の関連を定義する

- dependent: :destroy とは？
- model
- 親のproductを削除したら関連するproduct_variantsを自動で一緒に削除する（物理削除の場合）
※モデル同士の関連を定義する

- belongs_to :product とは？
- model > variant
- このバリアントは必ず一つのproductに属する
※モデル同士の関連を定義する

- controllerの各アクションは「画面に必要なレコードをmodel経由で引っ張ってきて@変数に閉じ込める」
DB -> products(テーブル) -> @products(変数)

- modelは「DBテーブルへの窓口 + バリデーション・scope(よく使う条件のショートカット)」
@product(変数) = Product.where(deleted: false)
Product が productsテーブルを表すModelクラス

- scopeはmodelで定義する。
  それをcontrollerでショートカットキみたいに使う

- active は scope の一種で "scope :active, -> {,}

- viewは「＠変数を使ってHTMLを組み立てる」

- link_to + *_path は「routesが定義したshow/indexなどへのURLを作るヘルパー」
link_to "表示文字列", "URL" (という形)

- before_action :set_product とは？
- controller
- 各アクションが実行される前に、実行する。privateとかで定義した内容を。
def set_product
  @product = Product.find(params[:id])
end  これを先に実行する。

- paramsとは？
- 「リクエストで送られてきた全データをまとめたハッシュ」
中身 (URL,クエリパラメータ,フォーム)
URL - GET /admin/products/12 = params[:id] => 12
クエリ - GET /admin/products?q=shirt&page=2 
         = params[:q] => "shirt"
           params[:page] => "2"
フォーム - <%= form_with model: @product do |f|%>
            <% f.text_field :name %> の場合
          params = {
            product: {
              name: "Tシャツ",
              description: "..."
              price_cents: "2980",
              published: "1"

- params.require とは？
params.require(:product) の場合
params[:product]が存在しなければエラー。
フォームが正しく送られたかの保証

- params.permit とは？
permit(:name)の場合 更新・保存を許可するカラムだけ明示

params.require(:product).permit(...)
productという塊が必須で、その中のこの項目だけ使っていい

- form_with とは？  自動分岐してくれる
- <%= form_with model: @product do |f| %>
- 中身 if @product.persisted?
        PATCH /admin/products/:id 更新になる
      else
        POST /admin/products 新規作成になる
      end

- persisted? とは？
- DBに保存済みか？（IDを持っているか？）
  Product.newは新規なので元々のIDがないからfalse

- notice とは？
- notice: "保存しました"
                 = flash[:notice] = "保存しました"
redirectが発生しないと表示がされない。画面遷移「前提」

- <% if @product.errors.any? %> 
この商品にエラーが一つでもあるか？を確認している
@product = 今扱っているオブジェクト
.errors  = バリデーションで失敗した結果を溜めている箱
.any?    = 中身が一件でもあるか？

- <% @product.errors.full_messages.each do |msg|
エラーメッセージを一件ずつ取り出す(整形済みの文章を返す)
・"Name can`t be black"
・"Price cents is not a number" など

- <li><%= msg %></li>
１行分のエラーメッセージをHTMLに表示する "Name~"を表示

- button_to "削除", toggle_deleted_admin_product_path(@product)
- URLを作る  そのURLにリクエストを送るボタンを作る

- method: :patch
HTTPメソッドをGET -> PATCHへ変更する(削除/更新のため)

- data: { confirm: "削除しますか？" }
ブラウザ標準の 確認ダイアログのシステム "誤操作防止"
(流れ) ボタンを押す > 「削除しますか」ポップアップ 
       > OKの場合  リクエスト送信
       > キャンセルの場合  何も起こらない

- patch :toggle_deleted, on: :member とは？
- routes
- on: :member = 1件のリソースに対する操作の意味
  patch :toggle_deleted 
  = PATCH メソッド
    toggle_deleted アクション名

- resources :products, only: %i[index show] とは
GET /admin/products index
GET /admin/products show  を一括で定義する

- include とは？
- controller
- N+1(クエリ)を防ぐための「先読み」指定

- N = レコード数 在庫10件 -> N = 10

- 1クエリ = DB問い合わせ1回 DBに投げるSQLの回数が一回

- q = "%#{params[:q]}%" とは？
- inventories controller
- 部分一致検索用の未字列を作っている
params[:q] = "シャツ"の場合 -> q = "%シャツ%" になる

- % の意味
% = ワイルドカード（0文字以上）
"T%" = Tから始まる
"%T%" = 含む（T)

- scope = scope.joins(:product).where(
  "products.name ILIKE ? OR product_variants.color ILIKE ? OR product_variants.size ILIKE ?",
  q, q, q
)
- where 全体の意味 : 商品名、カラー、サイズのどれかにqを含むSKUを全部取ってくる
- joins(:product) product_variantsからproductカラムを参照するために必要
- ILIKE 大文字小文字を区別しないためにつける

- case params[:stock_state] とは？
- 在庫状態フィルタ（UIのフィルタ切り替え用）

- page = params[:page].to_i とは？
- params[:page] は
/admin/api/inventories?page=2 -> params[:page] = 2
- to_i は
計算できる数値に変換  "2".to_i -> 2   nil.to_i -> 0

- page = 1 if page < 1 とは？
- ページ番号の下限ガード 
page=0, page=-1, page未指定  全部1ページ目扱いにする

- total_pages = (total.to_f / per_page).ceil とは？
- 総ページの計算をしている
- to_fは 21 / 20 -> 1(無い場合) 21.to_f / 20-> 1.05
- ceilは 1.05.ceil = 2 にする

- variants = scope
  .limit(per_page)
  .offset((page - 1) * per_page)
- limit/offset = DBレベルでページング

- variants.map do |v| とは？
- 全体の意味:ActiveRecordオブジェクトをJSON用Hashに変換
- mapは 配列を別の配列に変換する
- |v|は 各ProductVariant、1件ずつ取り出して処理

- updated_at: v.updated_at&.iso8601 とは？
- iso8601は API標準の日時フォーマット
- &.は updated_atがnilならエラーにせずnillを返す

- ActiveRecordオブジェクトとは？
SQL を書かずに Ruby で DB を操作できる存在
(例) variant = ProductVariant.find(1)
     ・product_variantsテーブルの１レコード
     だけど Ruby 的にはオブジェクト
※簡単に使えるみたいなイメージ

- Hashとは？
キーと値のセット (例) id: 1

- JSONとは？
データをやり取りするための文字列フォーマット
なぜ必要？JSとRailsの共通語（API=JSON返す・受け取る仕組み

- bulk_updateとは？そもそも
在庫をまとめて更新するためのAPI
***
複数SKU在庫を安全に一括更新し、壊れた入力・業務エラー・存在しないIDを全て正しいHTTPステータスに変換するAPI
***

- HTTPステータスとは？
処理結果を機械的に伝える番号(200 OK, 400 Bad Request)

- raise ActionController::BadRequest,"updates must be an array" unless update.is_a?(Array)
意味 : updates が配列じゃなかったら、404エラーにする
(分解する)
- updates.is_a?(Array)
updatesは配列か？
- unless
違ったら
- raise
例外を投げる

- updated_count = 0 はなぜ必要？
何件更新できたかを返すため

- ProductVariants.transition do とは？
全部成功するか、全部失敗するか
エラーが一つでもあると更新しない仕組み

- updates.each do |row|
updates = 配列
row = {id: 1, stock: 10}みたいな配列

- row.fetch(:id)とrow.fetch(:stock) 意味は？
fetchの意味 : キーがなければ例外(必須項目チェックを兼ねる)

- stock_i = Integer(stock)とは？何してる？
Integer("10") -> 10
Integer("a") -> ArgumentError
「数値でなければ即エラー」

- stock_iとは？
stock は params由来(文字列)、
stock_i は Integerに変換された値
xxx_s は string、xxx_at は datetime

- raise ActiveRecord::RecordInvalid ~ if stock_i<0
意味 :在庫は０以上、負数は業務的にNG

- variant = ProductVariant.find(id)とは？
・指定されたSKUをDBから取得
・なければRecordNotFound

- variant.update!(stock: stock_i)
update!の"！"
・成功 -> OK
・失敗 -> 例外

- update_count += 1とは？
・成功した分だけカウント
・ロールバックされたら全部無効

- colspanとは？
- HTML  <td colspan="4">Loading...</td> 4列分
- 横方向に何列分使うか
[1/20]
- document.addEventListener("DOMContentLoaded", () =>  とは？
- javascript(invent)
- ページが実行されたら実行

- fetch("/admin/api/inventories)
在庫APIを叩く

- .then(res => res.json())
JSONに変換

- const tbody = document.getElementById ("inventory-body")
tbody.innerHTML = ""
表を一回まっさらにする

- data.variants.forEach(v => {
SKU（variant）を一行ずつ処理

- tr.innerHTML = `...`
行HTMLを組み立てる

- tbody.appendChild(tr)
表に追加

- console.log("inventories.js loaded") とは？
このJSファイルが本当に実行されたか確認（通電テスト）

- const tbody = document.getElementById("inventories-body")とは？
・document: 今表示されているHTML全体
・getElementById("inventories-body")
id="inventories-body"を持つ要素を一つ探す
・const tbody: 見つけた要素をtbodyという名前で保存

- constとは？
再入力できない変数（DOM変数）

- letとは？
数値が変わる変数

- if(!tbody){
  console.error("inventories-body not found")
  return
}
全体の意味: `tbody`が見つからなかった時の保険
`!tbody`: tbodyがnillならtrue
`console.error`: 赤文字でエラー表示
`return`: このJSの処理をここで終了

- const tr = document.createElement("tr")
<tr></tr>をJSで新しく作る

- tbody.appendChild(tr)
作った<tr>を<tbody>の子として追加する

- .catch(err =>{
  console.error(err)
  })
全体の意味: fetchやthenの途中でエラーが起きたらここに来る
`err`: 起きたエラー内容の表示
`console.error(err)`: Consoleに赤文字で出す
何も表示されない理由を知るため

- function collectUpdates() {...}  
「collectUpdates」という名前の処理を定義(メソッド的な)

- updates = []とは？
updatesという配列(Array)を作っている(空の箱)

- document.querySelectAll(...)
指定条件に合う要素を全部取得

- inputs.forEach(...)
inputを１つずつ処理するループ

- input.dataset.variantId
data-variant-id="123" -> "123"を取得
「variantのID」

- updates.push({...})
{ id, stock }を配列に追加

[
  { id: "1", stock: "10" },
  { id: "2", stock: "0" }
]   この形が返ってくる

- return updates 完成した箱を返す

- if (saveBtn) {
保存ボタンが存在するか確認

- saveBtn.addEventListener("click", () => {
保存ボタンがクリックされたときに処理を実行
() => {} は「クリック時に動く関数」

- const updates = collectUpdates()
画面上の input から在庫変更内容を集める
返ってくる形 [{ id: "1", stock: "10" }]

- collectUpdates()とは？
元の値と今の値が違う行

- fetch("/admin/api/inventories/bulk_update", {
Rails の API にHTTPリクエストを送る

- method: "PUT",
HTTPメソッド「既存データを更新」

- headers: {
リクエストにつけるメタ情報

- "Content-Type": "application/json",
送るデータは JSON形式

- "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
Railsの CSRF対策

- CSRFとは？
この操作は本当にこの画面から送られたか？を確認するための鍵
「不正リクエスト防止」

- body: JSON.stringify({ updates })
実際に送るデータ { updates: [...] }をJSON文字列に変換

- .then(async res => {
サーバーからのレスポンスを受け取る

- asyncとは？
awaitを使える関数にする宣言

- resとは？
HTTPレスポンス全体

- const json = await res.json().catch(() => ({}))
レスポンスのJSON本文を取り出す

- awaitとは？
非同期処理が終わるまで待つ

- if (!res.ok) throw json
HTTPステータスが200系出なければエラー扱い 404とか検知

- })
  .catch(err => {
途中でエラーが起きた場合ここにくる

- alert(err.message || "保存の失敗しました")
エラーメッセージ表示
[1/21]
- input.dataset.originalStockとは？
HTMLに埋めた「元の在庫数」をJSから読むための名前
(dateset.xxx)

- const original = input.dataset.originalStockとは
「このinputが最初に表示された時点の在庫数を取得している」

- if (original !== current) {とは？
最初の値と今の値が違う場合だけ更新対象にする
・original: 最初の値
・current: 今入力されている値

- if (updates.length === 0) {とは？
何も変更しないのに保存ボタンを押したって意味
・updates: 変更が合った在庫だけを集めた配列
updates.length === 0 1件も更新されていない

- getElementById("inventories-body")とは？
HTMLの中から<tbody id="inventories-body">これ一個とる

- tbodyとは？
とってきた<tbody>そのもの（表の中身を書き換える場所

- Elementとは？
HTMLの１要素（div/input/load)

- Eventとは？
ユーザー操作が発生した出来事（click/submit/load)

- Elとは？
Elementの略

- function renderRows(variants) {...}とは？
function(処理の塊に名前つけるもの)
renderRows(関数名「行を描写する」の意味)
variants(渡されるデータ)

- loadInventoriesとは？
自分で定義した関数名「在庫一覧を読み込む一連の流れ」

- infoとは？
<span>要素。「page1/3」を表示する部品

- ${...}はなに？
文字列の中に変数を埋め込むのに使う

- history.replaceState(...)とは？
history(ブラウザの履歴操作API)
replaceState(ページ遷移せずにURLだけ書き換える)

- location.pathnameとは？
今のURLのパス部分

- tbody.querySelectorAll("input[data-variant-id]")
・querySelectorAllとは？
CSSセレクタで複数要素を取得する
その後ろは条件。tbody内、data-variant-idを持つinput

- form.addEventListener("submit",(e) => {...})
・submitイベントを監視
・フォームを送信されたら即実行
(e)は発生したイベントそのもの

- e.preventDefault()とは？
本来の動作を止める

- try {...} catch (err) {...}とは？
エラーが出るかもしれない処理を囲う

- JSON.stringify(...)とは？
JSのオブジェクト -> 文字列(JSON) 変換する。

- err.message || err.error || "保存に失敗した"
意味:err.messageがあればそれ、なければerr.errorそれもなければ固定文言
[1/22]
- deviseとは？
認証（ログイン機能）をまとめて提供するRails用ライブラリ
devise :database_authenticatable, :registerable,
       :recoverable, :rememberable, :validatable
・database_authenticatable メール + ログインできる
・registerable 会員登録できる
・recoverable パスワード再設定できる
・validatable email/passwordの最低限バリデーション

- enumとは？
状態機械の入口
[1/24]
- descriptionとは？
商品説明文

- form_actionとは？
formがどのURLに送信するか

- quantityとは？
数量

- value="1" min="1"
value = 初期状態が１
min = １未満は入力できない

- sessionとは？
- cart = session[:cart] || {} # { "variant_id" => quantity }
- ブラウザごとにRailsが自動で持っている一時保存領域

- variant_ids = cart.keys.map(&:to_i) とは？
・cart.keys = ["12", "18"] sessionは文字キーになる
・map(&:to_i) [12, 18]
つまり「カートに入っているSKUのid一覧を整数で作っている

- qtyとは？
quantityと同義（数量）

- <%= v.product.name %> (<%= v.color %>/<%= v.size %>) x <%= item.quantity %>
この商品（色/サイズ）かける 数量

- redirect_backとは？
直前のページへ戻す（どこから来たかを考慮できる）

- fallback_locationとは？
refererが存在しない場合の逃げ道

- if customer_signed_in?
    item = CartItem.find_or_initialize_(customer: current_customer, product_variant: variant)
    item.quantity = (item.quantity || 0) + qty
    item.save!
・initialize「まだDBに存在しないオブジェクトを作るだけ」
・find_or_initialize「あれば取得/なければnewする」

- cart = session[:cart] ||= {}とは？
session[:cart]がまだなければ{}を入れる

- to_sとは？
文字列に変換する

- sumとは？
- @cart_items.sum { |item| ... }
- 配列の各要素をブロック評価して合計する

- number_to_currency(
    @total_cents / 100.0,
    unit: "¥",
    precision: 0
)
・number_to_currency: 表示専用ヘルパー (数値->金額表示)
・total_cents /100.0: 
total_centsは整数(2980円->298000cents)
・unit: "¥": 通貨の表示単位
・precision: 0: 小数点以下の桁数(日本円は少数不要)

- unlessとは？
条件がfalseの時、実行(ifの逆)

- is_aとは？
クラス判定(そのオブジェクトが指定したクラスか？)
"abc"  -> .is_a(string) trueになる

- Hashとは？
Rubyのクラス(型) 文字列、数量etc
[1/27]
- stripe_controllerとは？
stripe の Webhook(Stripe->あなたのサーバー)を受け取る
入口のコントローラー

- skip_before_action:verify_authenticity_tokenとは
CSRF検証をスキップする(Stripe外部からのPOSTのため)
「つまりセキュリティ対策が必要になる」

- payload = request.raw_postとは？
・request : 「今来たHTTPリクエスト」オブジェクト
・raw_post : そのリクエストの本文(body)を生の文字列で取る

- sig = request.env["HTTP_STRIPE_SIGNATURE"]とは？
・env : HTTPリクエストの環境情報(ヘッダーなどが入る)
・"HTTP_STRIPE_SIGNATURE" : StripeがWebhookにつける署名ヘッダー 「このリクエストはStripeが送った」

- secret = ENV.fetch("STRIPE_WEBHOOK_SECRET")とは？
・ENV : OSの環境変数
・fetch("STRIPE_WEBHOOK_SECRET"): その環境変数を取得
Webhook secret は Stripe側が発行する共有秘密鍵
「これがないと署名検証できない」

- event = Stripe::Webhook.construct_event(payload, sig, secret)とは？
・payload(生本文)とsig(署名ヘッダー)を
 secret(Webhook secret)で検証して正しければeventを返す

[payload][sig][secret][event]
この4つで、そのPOSTが本当にStripeから来たものかを検証する

- return head :ok if stripeEvent.exists?(event_id: event.id)とは？
・head :ok :本文なしでHTTP200を返す(stripeに受け取ったと伝える)
・return : その場で処理終了
・StripeEvent.exists?(event_id: event.id) :
DBに「このevent_idを処理済みとして記録しているか？」を確認

- StripeEvent.create!(event_id: event.id, event_type: event.type)とは？
「このStripeイベントを処理した」という記録をDBに残す」
・event.id : Stripeが付けるイベント固有ID
・event.type : イベント種別(例 checkout.session.cpd)

- case event.type/when"checkout.session.completed"
Rubyの分岐構文(case/when)
event.typeの文字列が"checkout.session.completed"に
一致したらその処理を実行

- event.data.objectとは？
Stripeイベントの本体データ

- head :okとは？
Stripe に「正常に受け取りました」と返す

- rescue JSON::ParserError, Stripe::SignatureVer
JSONが壊れてる or 署名が不正な場合

- head :bad_requestとは？
Stripe に「不正リクエスト」と返す

- order_id = session_obj.metadata&.[]("order_id")
Checkout Session の metadata(Hash)から order_id を取り出す

- metadataとは？
「Stripe側に保存できる、任意のキー・バリューのメモ」
 Stripe Checkout Sessionに作った アプリとStripeを繋ぐ

- order_idとは？
RailsのOrderレコードの主キー

- Checkout開始時の流れ
1.Railsで[Order.create!]する -> order.id = 123
2.Stripe Checkout Sessionを作る 
-> metadata : {order_id = 123 }
3.支払い完了
4.WebhookでStripeから通知が来る
5.metadata["order_id"]を見て ->どのOrderの支払いか特定

- return if order.paid?とは？
既に paid の注文は二重処理しない

- Order.transaction doとは？
在庫減算・注文状態更新を原始的に行う

- v = ProductVariant.lock.find(item.product_variant_id)とは？
対象バリアントをロック付きで取得

- lockとは？
DBレベルで「同時更新を禁止するロック」

- if v.stock < item.quantityとは？
在庫不足チェック

- order.update!(status: :failed)
支払いは完了しているが、在庫確保に失敗 -> failed扱いにする

- order.order_items.each do |item|とは？
在庫減算フェーズ

- v.update!(stock: v.stock - item.quantity)とは？
在庫を確定減算

- order.update!(
    status: :paid,
    paid_at: Time.current,
    stripe_payment_intent_id: session_obj
                                   payment_intent
)
注文を確定にする
・update : 決済完了処理
・paid_at : 決済が完了した時刻
・Time.current : Railsのタイムゾーンに沿った現在時刻
・payment intent : Stripeの支払い処理単位
・stripe_payment_intent_id : Stripe側の支払い識別子
(3行目はStripe側の支払いiDを注文に紐づける)

- CheckoutsControllerとは？
カートの内容を確定してStripe決済を開始する
ためのコントローラー
カート->注文(Order)を作成->StripeCheckout開始の入り口

- build_cart_rows!とは？
カートの中身を"決済・注文用の正規データ"に変換するメソッド

- rowsとは？
カート全体(バリアント、数量、単価、小計)

- rとは？
1商品分の情報(rowsの中の)

- rows = build_cart_rows!
  total_cents = rows.sum { |r| r[:subtotal_cents]}
  raise ActiveRec::RecordInvalid if total_cents <0
・空カート防止
・金額0円防止

- order = Order.create!(
    status: :pending,
    total_cents: total_cents,
    ...
)
Orderを作る この時点ではまだ支払われてない注文「pending」

- session_obj = Stripe::Checkout::Session.create()
Stripe Checkout Sessionを作る
stripeに「支払い画面を作って」と依頼

- metadata: { order_id: order.id }
Webhookで「どのOrderの支払いか」を判別するため

- order.updata!(stripe_checkout_session_id: session_obj.id)とは？
セッションIDを保存

- redirect_to session_obj.url, allow_other_host: true
Stripeページへのリダイレクト

- allow_other_host: trueとは？
自分のサイト以外へのリダイレクトを許可するためのオプション

- if customer_signed_in?
会員/ゲストの分岐
・会員 -> DB (cart_items)
・ゲスト -> session[:cart]

- raise ActiveRecord::RecordNotFound if v.deleted?
非公開商品
- raise ArgumentError if qty < 1
在庫不足
- raise ArgumentError if v.stock < qty
不正数量
「決済前に必ず落とす」

- success_url: order_url(order) + "?paid=1"とは？
Stripe決済が完了した後、ユーザーが戻されるURL
・order_url(order) = /orders/:id
・?paid=1 = クエリパラメータ

- unit_price_centsとは？
一個当たりの価格

- variants = items.map(&:product_variant)とは？
variants = items.map {|item| item.product_variant}
と同じ意味
・&: 「各要素に対してこのメソッドを呼ぶ」ショートハンド

- qty_map = item.index_by { |i| 
i.product_variant_id}.transform_value(&:quantity)
目的 :「variant_id -> 数量」のハッシュを作る

- index_byとは？
配列 -> ハッシュに変換

- |i|とは？
ただの変数名(名前はなんでもいい)

- qty_mapとは？
数量マップ「このvariantは何個買われている？」

- transform_values(&:quantity)とは？
キーはそのまま、値だけ変換(idじゃなくqtyを取得)

- &:quantityとは？
|value| value.quantityの略

- transform_keys(&:to_i)とは？
キーを文字列 -> 整数に変換

- transform_value { |v| Integer(v) rescue 0 }
・transform_value : キーはそのまま値だけ変換
・Integer(v) : 不整地を検出(数字以外を弾く)
・rescue : 失敗したら0を返す、例外が発止した時に分岐させる
・キー(key) : IDみたいな感じ、２番の商品が４個(値)ある

- <strong>
太字。「強調」

- <% has_items = customer_signed_in? ? @cart_items.present? : @guest_items.present? %>
- cart.show
- 三項演算子(Ruby構文)。条件(?) 真 : 偽
もしログインできたら@cart_itemsが空じゃないか？
そうでなければ(ゲストなら)@guest_itemsが空じゃないか？

- &&とは？
論理AND (全部trueの時実行)

- @paid_paramとは？
URLに?paid=1がついている

- @order.paidとは？
DB上の注文ステータスがpaid

- include?とは？
includesとは"別" 配列に要素が含まれているか

- ! (update!)など
失敗すると例外(exception)を投げる
その例外がtransaction内で発生しrescueされない
自動でrollbackされる

- rollbackとは？
途中までのDB更新を全部無かったことにして元に戻す

- eとは？ rescue => e
例外を捕まえて、その例外オブジェクトをeという変数に入れる
・e.class : 例外の型
・e.message : 例外メッセージ

- ok= とは？
トランザクション内の処理が成功したか失敗したかを、
トランザクション外に持ち出すため
「なぜ外に持ち出す？」Rollbackを避けるため。巻き戻り防止

- blank? とは？(order_id.blank?)
空かどうか判定する nil/空文字/想定外 を一括で弾ける

- lock/with_lock とは？
DBの行(レコード)をロックする
(同じデータを同時に触れないように/二重減算を防止)

- begin とは？
(Ruby構文)
begin
~処理~
rescue
~例外時の処理~
end

- StripeEvent.find_or_create_by!(event_id: event.id) do |se|
二重実行防止「event.idをDBに保存し、処理済みか？を判定」

- se.event_type = event.typeとは？
これは「何おためのイベントだったか」を保存する

- case event.typeとは？
case「条件分岐」

- when "checkout.session.completed"とは？
支払い完了イベントが来た時だけ処理する

- handle_checkout_completed(event.data.object)の
event.data.objectは「そのイベントの本体データ」

- backtraceとは？(e.backtrace)
例外が起きた「呼び出し履歴(そのファイルの何行から来たか)」
first(10)は上位10件だけログに出す

- head :internal_server_errorとは？
500を返す。stripeは再送する

- handle_checkout_completed(session_obj)とは？
checkout.session.completedが来たときに、自分のDBの注文をpaidにし、在庫を減らす

- order_id = session_obj.metadata&.[]("order_id")
metadata : Stripe側に保存できる任意の「key-value」
Checkout Session作成時に metadata {order_id: order.id}を入れた。order_idを取り出して、自分のOrderを特定する

- CheckoutControllerの役割は？
・カートを「検証」
・注文をpendingで保存
・stripeが理解できる形式に変換
・Stripe Checkoutに投げる

- params[:xxx]がつく理由
- city: customer_signed_in? ? current_customer.city : params[:city],
- 形は 質問? 会員 : ゲスト params[:city]
DBに保存されていない情報はparamsを使う。会員はすでにDBにあるからparamsがいらない

- session[:guest_order_ids] = Array(session[:guest_order_ids])
session[:guest_order_ids] << order.id
session[:guest_order_ids].uniq!
- ゲストが自分の注文だけ"order/show"で見られるようにする
・Array(x) : nil->[] 配列->そのまま
・<< : 配列の末尾に追加
・uniq! : 重複防止

- allow_other_host: true
外部ドメインへのリダイレクトを許可(デフォルトが禁止)

- order.update!(stripe_checkout_session_id: session_obj.id)
- stripe_checkout_session_idを保存する
(なぜ)Webhookで「その注文の決済か」を紐づけるため

- items.map(&:product_variant)
items.map { |i| i.product_variant } これと一緒

- qty_map = items
  .index_by { |i| i.product_variant_id }
  .transform_values(&:quantity)
- index_by + transform_values
- variant_id -> 数量 高速・安全に数量を参照する

- cart = {} unless cart.is_a?(Hash)
セッションが壊れていた場合の保険
(nil/文字列/配列) -> 空カート扱い

- transform_keys(&:to_i)とは？
型を合わせる 文字列キー -> 整数ID

- Integer(v) rescue 0
数値以外は無効扱い

- rows.map
内部用構造 -> Stripe形式への"変換"

- metadata: { order_id: order.id } とは？
metadata形式にする(Webhook側に渡すため)














