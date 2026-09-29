---
title: "API 參考"
url: "https://developer.oen.tw/api/"
---

> 來源：https://developer.oen.tw/api/（自動產生，請勿手動修改）

# API 參考

這裡是 Payment API 每一支端點的完整規格。第一次串接請先看[快速開始](../developers/quickstart.md)。

所有欄位、限制與錯誤碼都依正式環境 v10.3.1.1 的程式核對。也可以下載 [OpenAPI 定義檔](https://developer.oen.tw/openapi/payment-api.json)，匯入 Postman 等工具。

## 網址

| 環境 | API | 結帳頁 |
| --- | --- | --- |
| 正式 | `https://payment-api.oen.tw` | `https://{merchantId}.oen.tw` |
| 測試 | `https://payment-api.testing.oen.tw` | `https://{merchantId}.testing.oen.tw` |

> 正式環境要先綁定固定 IP
> 
> 正式環境只接受已綁定的 IP，其他來源一律回 HTTP 403。測試環境沒有這個限制。見[固定 IP 白名單](../developers/ip-allowlist.md)。

## 驗證

每個請求都帶：

```http
Authorization: Bearer <token>
Content-Type: application/json
```

-   token 在 CRM 產生，測試與正式環境各一把，不能互用。見[驗證與 token](../developers/authentication.md)。
-   `Bearer` 要照這個大小寫，中間只有一個空白。
-   有 body 的請求要帶 `merchantId`，而且必須是 token 所屬的網域。
-   **只能從伺服器呼叫**。API 不支援瀏覽器跨網域請求，token 也不能放在前端。

## 回應格式

成功時 HTTP 200：

```json
{ "code": "S0000", "data": { }, "message": "" }
```

失敗時：

```json
{ "code": "V0001", "data": {}, "message": "must have required property 'orderId'" }
```

-   程式判斷請看 `code`，`message` 的文字可能調整。
-   付款結果不明時是 HTTP 409，另外帶 `"retryable": false`，見 [C026](error-codes.md)。
-   個人身分商家被風控拒絕時（`K0001`），另外帶 `detail`。
-   沒有值的欄位不會出現在回應裡。
-   找不到路徑時回 404、不支援的 HTTP method 回 405，body 是純文字，不是上面的 JSON 格式。
-   被正式環境的 IP 白名單擋下時回 403，body 只有 `message` 欄位（通常是 `Forbidden`），沒有 `code`。

## 欄位驗證

-   body 必須是合法的 JSON，否則回 500 `F0001`。
-   規格裡沒有的欄位會被忽略，不會報錯。所以欄位名稱拼錯時不會有任何提示，請對照各端點的欄位表。例如 Payment API 沒有 `webhookUrl`、`cancelUrl` 這類欄位，付款通知網址在 CRM 設定。
-   驗證失敗回 400 `V0001`，`message` 會列出所有不符合的規則，但不一定有欄位名稱。

## 分頁

[查詢交易列表](list-transactions.md)與[查詢商店定期購列表](list-subscriptions.md)每頁 50 筆。回應的 `page` 是下一頁的分頁標記，原封不動放進下一次請求的 `?page=`；沒有下一頁時是 `null`。標記無效時回 500 `F0001`。

## 時間

-   回應的時間都是 UTC 的 ISO 8601 字串，例如 `2026-09-28T02:40:25.502Z`。
-   你送出的日期（`startDate`、`expectedPayoutDate`）格式是 `yyyy/MM/dd`，以台北日期解讀。
-   定期定額每天台北時間上午 9 點扣款。

## ID

| 名稱 | 格式 | 用在 |
| --- | --- | --- |
| 交易 `id`／`transactionId` | 27 字元英數 | 組結帳頁網址、付款通知、[查詢交易明細](get-transaction.md) |
| 交易編號 `transactionHid` | `P` + 日期 + 8 碼，共 17 字元，例如 `P20260928AB12CD34` | [退款](refund.md)、對帳、CRM 搜尋 |
| 定期定額編號 | `S` + 日期 + 8 碼，共 17 字元 | [查詢](get-subscription.md)與[取消定期定額](cancel-subscription.md) |
| `orderId` | 你自己的訂單編號 | [用訂單編號查詢](list-order-transactions.md) |

## 冪等性與頻率限制

-   Payment API **沒有** `Idempotency-Key`。同樣的請求送兩次，就會建立兩筆交易。逾時或收到 5xx 時，先查詢再決定要不要重送，見[錯誤處理](../developers/errors.md)。
-   目前沒有對個別商家限制請求頻率，但請不要高頻率輪詢；日後可能開始限制。

## 端點一覽

| Method | Path | 說明 |
| --- | --- | --- |
| POST | [`/checkout`](checkout.md) | 建立單次付款 |
| POST | [`/checkout-subscription`](checkout-subscription.md) | 建立定期定額 |
| POST | [`/checkout-schedule`](checkout-schedule.md) | 建立預約定期定額 |
| POST | [`/checkout-token`](checkout-token.md) | 建立綁卡頁 |
| POST | [`/token/transactions`](token-transactions.md) | 用 token 扣款 |
| POST | [`/token/subscriptions`](token-subscriptions.md) | 用 token 建立定期定額 |
| GET | [`/transactions/{id}`](get-transaction.md) | 查詢交易明細 |
| GET | [`/transactions`](list-transactions.md) | 查詢交易列表 |
| GET | [`/order/{orderId}/transactions`](list-order-transactions.md) | 用訂單編號查詢交易 |
| POST | [`/refunds/{transactionHid}`](refund.md) | 退款 |
| GET | [`/subscriptions/{id}`](get-subscription.md) | 查詢定期定額明細 |
| PUT | [`/subscriptions/{subscriptionHid}`](cancel-subscription.md) | 取消定期定額 |
| GET | [`/subscriptions`](list-subscriptions.md) | 查詢商店定期購訂單列表 |

需要傳送完整卡號的 API 必須符合 PCI DSS 規範，不在本站公開。若你的情境確實需要，請聯絡業務人員個別討論。
