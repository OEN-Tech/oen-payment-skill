---
name: oen-payment
description: 應援科技 OEN Payment API（應援金流）串接助手：建立結帳頁、定期定額、綁卡與 token 扣款、退款、查詢交易、接收付款通知（webhook）、解讀錯誤碼。只要使用者提到 oen payment、oen 金流、應援金流、應援 API、應援結帳、payment-api.oen.tw、payment-api.testing.oen.tw、{網域}.oen.tw/checkout、checkout-subscription、checkout-schedule、checkout-token、token/transactions、payment_error、C026、developers.oen.tw、developers.oentech.ai，或在應援的情境下要做 checkout、subscription、定期定額、refund、退款、webhook、付款通知、存卡、token 扣款、對帳，就使用這個 skill；即使沒有明講「應援」，只要程式或網址指向 oen.tw 的金流也要使用。Use it for OEN Payment API work — checkout pages, recurring subscriptions, saved-card token charges, refunds, webhook handlers, reconciliation and error codes. 不適用其他金流（Stripe、綠界 ECPay、直接串接藍新金流、PayPal）。
---

# 應援 Payment API 串接助手

協助開發者串接應援科技（OEN）的 Payment API：產生建立交易、接收付款通知、退款、查詢與對帳的程式，並解釋錯誤碼。

`references/docs/` 是應援開發者文件站原樣匯出的頁面，依正式環境 v10.3.1.1 查核；匯出來源記在 `references/docs/manifest.json` 的 `sourceCommit`。回答欄位、限制與錯誤碼之前，先讀對應的頁面，不要憑記憶，因為舊版文件與網路上的範例有很多已經不對。下面每條規則都附上出處（路徑都在 `references/docs/` 底下）。本檔或 references 跟文件站不同時，以文件站為準。

## 什麼時候用

- 寫或修改呼叫 `payment-api.oen.tw`、`payment-api.testing.oen.tw` 的程式。
- 設計結帳、定期定額、存卡扣款、退款、付款通知接收端或對帳流程。
- 解讀錯誤碼、`payment_error`、交易狀態，或追查「沒收到通知」「上線就 403」這類問題。
- 使用者問的是別家金流，或只是一般的付款概念、跟應援無關時，不要套用這裡的規則。

## 先讀哪一頁

全部頁面與網址見 `INDEX.md`；端點一覽與共通規則（回應格式、ID、分頁、時間）見 `api/index.md`。

| 任務 | 先讀 |
| --- | --- |
| 第一次串接、單次付款 | `developers/quickstart.md`、`developers/one-time.md`、`api/checkout.md` |
| 付款方式（超商代碼、ATM、LINE Pay、Apple Pay） | `developers/payment-methods.md` |
| 接收付款通知（webhook） | `developers/webhooks.md`、`api/objects/webhook.md`、`api/get-transaction.md` |
| 定期定額 | `developers/subscriptions.md`、`api/checkout-subscription.md`、`api/checkout-schedule.md`、`api/get-subscription.md`、`api/cancel-subscription.md` |
| 綁卡、用 token 扣款 | `developers/saved-cards.md`、`api/checkout-token.md`、`api/token-transactions.md`、`api/token-subscriptions.md` |
| 退款 | `developers/refunds.md`、`api/refund.md` |
| 查詢、補救漏掉的通知、對帳 | `developers/querying.md`、`api/list-order-transactions.md`、`api/list-transactions.md` |
| 交易與定期定額的欄位、狀態 | `api/objects/transaction.md`、`api/objects/subscription.md` |
| 錯誤碼、能不能重試 | `developers/errors.md`、`api/error-codes.md` |
| token、401 | `developers/authentication.md` |
| 測試環境、正式環境 403、上線前檢查 | `developers/environments.md`、`developers/ip-allowlist.md`、`developers/go-live.md` |
| 該用哪一種產品、Embed、Subscription API | `start/choose.md`、`products/embed.md`、`products/subscription-api.md` |
| 名詞、常見問題 | `start/glossary.md`、`start/faq.md` |

## 環境與驗證

| 環境 | API | 結帳頁 |
| --- | --- | --- |
| 測試 | `https://payment-api.testing.oen.tw` | `https://{merchantId}.testing.oen.tw` |
| 正式 | `https://payment-api.oen.tw` | `https://{merchantId}.oen.tw` |

- 每個請求帶 `Authorization: Bearer <token>` 與 `Content-Type: application/json`。有 body 的請求要帶 `merchantId`，也就是網域名稱（`ming.oen.tw` 就是 `ming`），而且必須是 token 所屬的網域；GET 不用帶。（`api/index.md`、`developers/authentication.md`）
- token 在 CRM「總設定」→「開發者」→「應援金流設定」產生。測試與正式各一把、不能互用；重新產生後舊的立刻失效。（`developers/authentication.md`）
- 只能從伺服器呼叫，API 不接受瀏覽器跨網域請求。（`api/index.md`）
- 開發與範例一律先打測試環境。測試環境不會真的扣款，但付款通知會真的送到測試環境 CRM 設定的網址。（`developers/environments.md`）

## AI 最常寫錯的規則

### 建立交易

1. **`productDetails` 一律必填。** `/checkout`、`/checkout-subscription`、`/checkout-schedule`、`/token/transactions`、`/token/subscriptions` 都要帶，各品項 `quantity × unitPrice` 的合計必須等於 `amount`，金額都是新台幣整數。有折扣或運費時，調整品項讓合計等於實付金額。沒帶回 400 `V0001`，合計不符回 `PRODUCT_AMOUNT_NOT_MATCH`。（`developers/one-time.md`、`developers/errors.md`、`api/checkout.md`）
2. **回應只有 `{ id, transactionHid }`，結帳頁網址要自己組**：`https://{merchantId}.oen.tw/checkout/{id}`，測試環境是 `{merchantId}.testing.oen.tw`。定期定額是 `/checkout/subscription/{id}`；預約定期定額是 `/checkout/schedule/{id}`，回應是 `{ id, subscriptionHid }`；綁卡頁是 `/checkout/subscription/create/{id}`。27 字元的 `id` 用來回查，`P` 開頭的 `transactionHid` 用來退款，兩個都要存進訂單。（`developers/environments.md`、`api/checkout.md`、`api/checkout-schedule.md`）
3. **結帳頁從呼叫 API 起算 5 分鐘內有效，綁卡頁 10 分鐘。** 所以要在消費者按下付款時才建立，建立後立刻導過去，不要先產生連結再寄出。逾時會導回 `failureUrl?payment_error=V0002`，綁卡頁是 `Y003`。（`developers/environments.md`、`developers/one-time.md`）
4. **`successUrl` 導回時不帶任何參數，也不代表付款成功。** 自己的訂單編號要放在網址裡，頁面再到後端查訂單狀態。`failureUrl` 會加上 `payment_error`，只用來顯示訊息；訂單編號用路徑帶，`failureUrl` 不要自帶 `?`。（`developers/one-time.md`、`api/error-codes.md`）
5. **只收新台幣**，`currency` 可以不帶。`allowedPaymentMethods` 是「加開」：信用卡一定會出現，Apple Pay 條件符合時自動出現。只有 `/checkout` 能選付款方式，定期定額與存卡只收信用卡。（`developers/payment-methods.md`）
6. **規格外的欄位會被直接忽略、不報錯。** Payment API 沒有 `webhookUrl`、`cancelUrl` 這類欄位，付款通知網址只能在 CRM 設定。（`api/index.md`）

### 付款結果與付款通知

7. **付款成功是 `charged` 或 `claimed`**，LINE Pay、藍新等由收單機構直接撥款的付款方式，成功就是 `claimed`。`charging` 是處理中：超商代碼、ATM 已取號等待繳費，或 LINE Pay 等待確認，這時不出貨，也不判失敗。消費者沒付款就離開時不會有任何通知，交易停在 `initiated`。（`api/objects/transaction.md`、`developers/one-time.md`）
8. **付款通知沒有簽章，任何人都能偽造。** 接收端先回 2xx，再用 body 的 `id`（27 字元）呼叫 `GET /transactions/{id}` 回查，比對 `orderId` 與 `amount`，依查到的 `status` 更新訂單。`charging` 的通知沒有 `success` 欄位，不能用 `!success` 判斷失敗。用 `purpose` 分辨通知種類（`charge`、`token`、`schedule_subscription`）。（`developers/webhooks.md`、`api/objects/webhook.md`）
9. **通知最多送 3 次**：第一次之後約隔 2 秒、4 秒再送，每次只等 10 秒，回 3xx 也算失敗。3 次都失敗就不會再送，也沒有後台重送。通知沒有事件編號，可能重複或順序顛倒，所以「標記已付款」要能重複執行；另外要排定期工作，把建立超過 15 分鐘仍沒有結果的訂單用 `GET /order/{orderId}/transactions` 補查。（`developers/webhooks.md`）

### 重試與錯誤

10. **沒有 Idempotency-Key。** 同樣的請求送兩次就建立兩筆交易，用 token 扣款時就是扣兩次。逾時、504、連線中斷時，先用 `GET /order/{orderId}/transactions` 查；查不到，或查到的是 `failed`，才重送。（`api/index.md`、`developers/errors.md`）
11. **409 `C026`（`PAYMENT_STATUS_UNKNOWN`，`retryable: false`）代表付款結果不明**，扣款可能已經發生。不要重送，也不要換一筆新訂單再扣；稍後查詢，一直是 `charging` 就帶交易編號聯絡應援。（`developers/errors.md`、`api/error-codes.md`）
12. **正式環境有固定 IP 白名單。** `payment-api.oen.tw` 只接受已綁定的出口 IP，其他來源回 HTTP 403，body 是 `{"message":"Forbidden"}`，沒有 `code`；有 `code: "A0001"` 的 401 才是 token 的問題。測試環境沒有白名單，所以常見「測試都正常、上線就 403」。請商家向應援申請，每個出口 IP 都要綁。程式要先看 HTTP 狀態碼，再讀 `code`。（`developers/ip-allowlist.md`、`api/error-codes.md`）

### 退款

13. **`POST /refunds/{transactionHid}` 的路徑用 `P` 開頭的交易編號**，不是 27 字元的 `id`。API 每筆交易只能成功退款一次，部分退款後剩下的金額不能再退；`amount` 不帶就是全額。（`developers/refunds.md`、`api/refund.md`）
14. **不只信用卡能用 API 退。** 信用卡、Apple Pay、LINE Pay 即時退回；已繳費的超商代碼、ATM 要帶 `remitInfo`（消費者的銀行帳戶，6 個欄位都必填），狀態先變成 `refunding`；還沒繳費的超商代碼會直接取消代碼（`cancelled`）。原交易有開電子發票時要帶 `productDetails`，合計等於這次的退款金額。退款逾時或回 500 時，先查交易的 `status` 與 `refundAmount`，不要直接重送。（`developers/refunds.md`）

### 定期定額與存卡

15. **扣款失敗預設不重扣。** 某一期失敗，定期定額就變成 `error`，之後所有期數都不會再扣。要重扣，請商家在 CRM「總設定」→「開發者」→「定期交易重試機制（Beta）」→「定期購買」開啟（最多重扣 2 次）。`numberOfPeriods` 最少 2，每期金額固定。（`developers/subscriptions.md`）
16. **取消只接受 `S` 開頭的定期定額編號**：`PUT /subscriptions/{subscriptionHid}`，一定要送 body（至少 `merchantId`），取消後不能恢復。`GET /subscriptions`（不帶 id）列的是應援商店的「定期購」訂單，不是 Payment API 的定期定額。（`api/cancel-subscription.md`、`developers/subscriptions.md`、`api/list-subscriptions.md`）
17. **綁卡的 token 只會經由 `purpose: token` 的付款通知送達**，沒有查詢 API，通知漏掉就只能請消費者重新綁卡。token 可以直接扣款，要當成密碼保存。用 token 扣款的結果以 API 回應為準，不會送付款通知。（`developers/saved-cards.md`）

### 查詢

18. **`GET /transactions` 列的是整個網域的所有款項**：除了 API 交易，也有商店訂單、捐款等其他收款（`C` 開頭）與負數的調整款項。只要 API 交易時，篩選 `P` 開頭或比對 `orderId`。`start`、`end` 要一起帶，以台北日期計算；`page` 是 `null` 才是最後一頁。（`developers/querying.md`、`api/list-transactions.md`）

## 回答與寫程式的流程

1. 判斷任務，依上面的表讀對應頁面；欄位以 `api/*.md` 的欄位表為準。
2. 沿用使用者專案的語言與框架，沒有線索時用 TypeScript。可以參考 `developers/quickstart.md` 的建立結帳（第 2 節）與付款通知回查（第 4 節）範例。
3. API 與結帳頁網址放設定檔，預設測試環境；token 從環境變數 `OEN_API_TOKEN` 讀取。
4. 處理回應時先看 HTTP 狀態碼，再讀 body 的 `code`：403 沒有 `code`，404、405 的 body 是純文字。（`api/index.md`）
5. 交付前對照 `developers/go-live.md` 逐項檢查，並提醒使用者正式環境要先申請 IP 白名單。
6. 文件沒有寫的行為，直接說文件沒有寫，請使用者向應援確認，不要自行推測。

## 安全

- API token 可以建立交易與退款，只能放在伺服器的環境變數或密鑰管理服務，不要寫進前端、App 或版本控制。（`developers/authentication.md`）
- 不要請使用者把 token 貼進對話。使用者已經貼出來時，提醒他到 CRM 重新產生，舊的會立刻失效。（`developers/authentication.md`）
- 需要實際呼叫 API 時，先確認用的是測試環境與測試環境的 token；正式環境會真的扣款與退款。（`developers/environments.md`）
- 測試卡號請使用者向應援的聯絡人索取。舊版文件列的固定測試卡號與金額規則都不是應援的規則，不要引用。（`developers/environments.md`）

## 不涵蓋

- 只教 `api/index.md` 端點一覽裡的 13 支公開端點。Hosted Checkout 沒有公開；需要傳送完整卡號的 API 要符合 PCI DSS，也不公開（`api/index.md`）。使用者有這類需求時，請他聯絡應援業務，不要自行推測端點或欄位。
- Embed 嵌入式付款、Subscription API、WooCommerce 外掛都要先請應援開通（`start/choose.md`、`products/embed.md`、`products/subscription-api.md`）。使用者沒有說已經開通時，先用 Payment API 回答。
- Payment MCP 是內部預覽版，尚未對外開放，不要提供安裝步驟，請使用者看 https://developers.oentech.ai/ai/mcp/ 。
- 手續費與費率不寫任何數字，請使用者到 CRM 查看或詢問應援業務。
- 開通付款方式、撥款、發票作業等商家後台操作，請商家看文件站的商家指南或聯絡應援客服。（`start/faq.md`）

## 文件站

- 開發者文件站：https://developers.oentech.ai （目前是預覽站，正式上線後改為 developers.oen.tw）。
- 要一次把完整文件交給 AI，用文件站的 `/llms-full.txt`；OpenAPI 定義檔是 `/openapi/payment-api.json`。
- 更新 `references/docs/`：用文件站匯出的 bundle 執行 `scripts/sync-docs.sh <bundle-dir>`，見 README。
