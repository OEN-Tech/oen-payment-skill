---
title: "錯誤處理"
url: "https://developers.oentech.ai/developers/errors/"
---

> 來源：https://developers.oentech.ai/developers/errors/（自動產生，請勿手動修改）

# 錯誤處理

## 錯誤回應

```json
{ "code": "V0001", "data": {}, "message": "PRODUCT_AMOUNT_NOT_MATCH" }
```

-   程式判斷請看 HTTP 狀態碼與 `code`。`message` 的文字可能調整，只用來記錄與除錯。
-   所有錯誤碼見[錯誤碼一覽](../api/error-codes.md)。

## 可不可以重試

| 你收到 | 可以重試嗎 | 怎麼做 |
| --- | --- | --- |
| 400 `V0001` | 不行 | 依 `message` 修正參數 |
| 400 `V0002` | 不行 | 先查詢目前狀態 |
| 400 `T0001`～`T0005` | 不要用同一張卡立刻重試 | 請消費者換卡或聯絡發卡銀行 |
| 400 `K0001`、`V0003` | 不行 | 聯絡應援 |
| 401 `A0001` | 不行 | 檢查 token，見[驗證與 token](authentication.md) |
| 403（沒有 `code`） | 不行 | IP 還沒綁定，見[固定 IP 白名單](ip-allowlist.md) |
| 409 `C026` | **不行** | 付款結果不明，見下方 |
| 500 `F0001` | 看情況 | 先看 `message`，見下方 |
| 504、逾時、連線中斷 | **先查再說** | 請求可能已經成功，見下方 |

## 付款結果不明時，不要再扣一次

> Payment API 沒有 Idempotency-Key
> 
> 同樣的請求送兩次，就會建立兩筆交易；用 token 扣款時就是**扣兩次**。所以結果不明時，絕對不要直接重送。

### 409 C026

回應是：

```json
{ "code": "C026", "data": {}, "message": "PAYMENT_STATUS_UNKNOWN", "retryable": false }
```

扣款可能已經發生，只是結果還沒確定。交易會停在 `charging`：

1.  不要重送，也不要建立新的訂單再扣一次。
2.  稍後用[訂單編號查詢](../api/list-order-transactions.md)確認交易狀態。
3.  一段時間後仍是 `charging`，請帶交易編號聯絡應援。

### 504、逾時、連線中斷

API 最多處理 29 秒，超過會回 504，但後面的處理可能還在進行，甚至已經成功。

1.  用[訂單編號查詢](../api/list-order-transactions.md)，看有沒有剛剛那筆交易。
2.  有，而且是 `charged` 或 `claimed`：當作成功，不要重送。
3.  有，而且是 `charging`：等一下再查。
4.  沒有，或是 `failed`：才可以重送。

### 500 F0001

| `message` | 原因 | 怎麼做 |
| --- | --- | --- |
| `Invalid date` | 查詢列表的 `start`、`end` 格式錯誤，或只帶一個 | 修正參數 |
| `Pagination parse failed` | `page` 分頁標記無效 | 用上一頁回傳的原值 |
| `Current charged amount too low` | 退款時，網域尚未撥款的金額低於 200 元 | 聯絡應援 |
| JSON 解析錯誤 | body 不是合法的 JSON | 修正 body |
| 其他 | 系統錯誤 | 查詢類可以稍後重試；建立交易、退款類請先查詢再決定 |

## 欄位驗證錯誤

-   驗證失敗回 400 `V0001`，`message` 會列出所有不符合的規則，例如 `must have required property 'productDetails'; must be >= 1`。
-   `message` 不一定有欄位名稱，請對照 API 參考的欄位表逐一檢查。
-   規格裡沒有的欄位會被忽略，不會報錯。欄位名稱拼錯時，常見的現象是「送了但沒效果」或「必填欄位缺少」。

## 常見錯誤

| message | 原因 |
| --- | --- |
| `must have required property 'productDetails'` | 沒帶商品明細。所有建立交易的 API 都要帶 |
| `PRODUCT_AMOUNT_NOT_MATCH` | 品項「數量 × 單價」的合計不等於 `amount` |
| `USER_NAME_AND_EMAIL_REQUIRED` | 網域有開通電子發票，但沒帶 `userName` 或 `userEmail` |
| `INVALID_PARAMS` | `merchantId` 和 token 的網域不同；或查詢的交易不屬於你的網域 |
| `PAYMENT_SERVICE_NOT_ACTIVATE` | 網域的金流服務還沒開通 |
| `LINE_PAY_NOT_ACTIVE` | 帶了 `linePay`，但 LINE Pay 還沒開通 |
| `START_DATE_MUST_GREATER_THAN_TODAY` | `startDate` 早於今天（用 token 建立定期定額時，今天也不行） |
| `must match format "uri"` | `successUrl` 或 `failureUrl` 不是完整網址，少了 `https://` |

## 回報問題時

請提供：網域名稱、環境（測試或正式）、呼叫時間、端點、交易編號或 `orderId`，以及完整的錯誤回應。**不要附上 token。**
