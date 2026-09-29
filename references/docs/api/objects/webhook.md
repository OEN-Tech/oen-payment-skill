---
title: "付款通知內容"
url: "https://developer.oen.tw/api/objects/webhook/"
---

> 來源：https://developer.oen.tw/api/objects/webhook/（自動產生，請勿手動修改）

# 付款通知內容

付款通知的處理方式、重送規則與回查做法，請先看[付款通知（webhook）](../../developers/webhooks.md)。這一頁列出每一種通知的欄位。

## HTTP 格式

-   `POST` 到你在 CRM 設定的「交易資料回傳網址位置」。
-   Header 只有 `Content-Type: application/json`。**沒有簽章，也沒有事件編號**。
-   用 body 的 `purpose` 分辨是哪一種通知。

| purpose | 什麼時候送 | 預設會送嗎 |
| --- | --- | --- |
| `charge` | 單次付款與定期定額每一期的結果；超商代碼、ATM 取號；LINE Pay 等待確認 | 會 |
| `token` | 綁卡頁完成或失敗 | 會 |
| `schedule_subscription` | 預約定期定額在結帳頁完成或失敗 | 會 |
| `refund` | 退款建立、完成或取消 | 要請應援開啟 |
| `subscription_cancelled` | 定期定額被取消（API 或 CRM） | 要請應援開啟 |
| `subscription_retry` | 定期定額扣款失敗後，已排定重扣或重扣次數用完 | 要請應援開啟 |

`refund`、`subscription_cancelled`、`subscription_retry` 三種要請應援在後台開啟「Webhook 新版事件」才會送出。

## charge

單次付款、定期定額每一期的結果。同一筆交易可能收到多則，例如超商代碼先送取號（`charging`），繳費後再送 `charged`。

| 欄位 | 型別 | 出現 | 說明 |
| --- | --- | --- | --- |
| `purpose` | `string` | 一定有 | `charge` |
| `id` | `string` | 一定有 | 交易的內部 id。用它呼叫 `GET /transactions/{id}` 回查 |
| `transactionId` | `string` | 一定有 | 同 `id` |
| `transactionHid` | `string` | 一定有 | 交易編號（`P` 開頭） |
| `merchantId` | `string` | 一定有 | 你的網域名稱 |
| `orderId` | `string` | 可能沒有 | 你的訂單編號 |
| `action` | `string` | 可能沒有 | `onetime` 或 `subscription` |
| `status` | `string` | 一定有 | 交易狀態：`charging`、`charged`、`claimed`、`authorized`、`failed` 等 |
| `success` | `boolean` | 可能沒有 | 只在最終結果才有：`status` 不是 `failed` 時為 `true`。取號、等待確認（`charging`）時沒有這個欄位 |
| `paymentMethod` | `string` | 可能沒有 | `card`、`applePay`、`linePay`、`cvs`、`atm` |
| `amount` | `number` | 可能沒有 | 金額 |
| `currency` | `string` | 可能沒有 | 幣別，**小寫**，例如 `twd` |
| `paymentInfo` | `string \| object` | 可能沒有 | 信用卡：卡號末四碼字串（Apple Pay 的付款通知可能不帶 `paymentInfo`）；超商：`{ cvsName, code, expiredAt }`；ATM：`{ bankName, bankCode, account, expiredAt }`；LINE Pay：LINE Pay 交易編號 |
| `authCode` | `string` | 可能沒有 | 授權碼 |
| `customId` | `string` | 可能沒有 | 你帶入的自訂資料 |
| `productDetails` | `array` | 可能沒有 | 建立交易時的商品明細 |
| `userPhone` | `string` | 可能沒有 | 消費者在結帳頁填的手機 |
| `createdAt` | `string` | 可能沒有 | **交易建立時間**，不是通知送出的時間 |
| `paidAt` | `string` | 可能沒有 | 付款完成時間 |
| `message` | `string` | 可能沒有 | 失敗原因。超商代碼、ATM、LINE Pay 逾期時是 `PAYMENT_EXPIRED`；3D 驗證開始後 10 分鐘沒完成是 `3DS_ABANDONED` |
| `subscriptionId` | `string` | 可能沒有 | 定期定額編號（`S` 開頭），定期定額才有 |
| `period` | `integer` | 可能沒有 | 定期定額的第幾期 |
| `numberOfPeriods` | `integer` | 可能沒有 | 定期定額總期數 |
| `isRetry` | `boolean` | 可能沒有 | 定期定額：這次是否為失敗後的重新扣款 |
| `failureCode` | `string` | 可能沒有 | 定期定額扣款失敗的原因：`invalid_card_number`、`invalid_cvv`、`expired_card`、`exceeds_credit_limit`、`payment_refused`、`duplicate_payment`、`charge_failed` |
| `scheduleStatus` | `string` | 可能沒有 | 定期定額狀態：`pending`、`trialing`、`active`、`retrying`、`error`、`cancelled`、`completed` |
| `nextChargeAt` | `string` | 可能沒有 | 定期定額下次扣款時間。請以[查詢定期定額明細](../get-subscription.md)為準 |

### 範例

```json
{
  "purpose": "charge",
  "action": "onetime",
  "merchantId": "ming",
  "orderId": "A20260928001",
  "id": "2HhndgEquCbDzC5OyVxWSGZmd2l",
  "transactionId": "2HhndgEquCbDzC5OyVxWSGZmd2l",
  "transactionHid": "P20260928AB12CD34",
  "status": "charged",
  "success": true,
  "paymentMethod": "card",
  "amount": 1200,
  "currency": "twd",
  "paymentInfo": "4242",
  "authCode": "831000",
  "customId": "cart-8812",
  "createdAt": "2026-09-28T02:40:25.502Z",
  "paidAt": "2026-09-28T02:41:03.118Z",
  "productDetails": [
    {
      "productionCode": "SKU-001",
      "description": "手沖咖啡豆 200g",
      "quantity": 2,
      "unit": "包",
      "unitPrice": 600
    }
  ],
  "message": ""
}
```

超商代碼取號時（還沒繳費，沒有 `success` 欄位）：

```json
{
  "purpose": "charge",
  "action": "onetime",
  "merchantId": "ming",
  "orderId": "A20260928002",
  "id": "2HhnkQ3vXy8LpA1cB0dE9fG2hIj",
  "transactionId": "2HhnkQ3vXy8LpA1cB0dE9fG2hIj",
  "transactionHid": "P20260928UV12WX34",
  "status": "charging",
  "paymentMethod": "cvs",
  "amount": 500,
  "currency": "twd",
  "paymentInfo": {
    "cvsName": "超商代碼繳費",
    "code": "XXXXXXXXXXXX",
    "expiredAt": "2026-09-30T02:00:00.000Z"
  },
  "message": ""
}
```

消費者繳費後，同一個 `id` 會再收到一則 `status: charged`、`success: true` 的通知。逾期未繳則是 `status: failed`、`message: PAYMENT_EXPIRED`。

## token

[建立綁卡頁](../checkout-token.md)後，消費者完成或放棄綁卡時送出。**這是拿到 token 的唯一管道**。

| 欄位 | 型別 | 出現 | 說明 |
| --- | --- | --- | --- |
| `purpose` | `string` | 一定有 | `token` |
| `id` | `string` | 一定有 | 建立綁卡頁時回傳的 `id` |
| `transactionId` | `string` | 一定有 | 同 `id` |
| `merchantId` | `string` | 一定有 | 你的網域名稱 |
| `success` | `boolean` | 一定有 | 是否綁卡成功 |
| `token` | `string` | 可能沒有 | 成功時才有。用來呼叫[用 token 扣款](../token-transactions.md)，請當成密碼一樣保存 |
| `paymentInfo` | `string` | 可能沒有 | 卡號末四碼 |
| `customId` | `string` | 可能沒有 | 建立綁卡頁時帶的自訂資料 |
| `message` | `string` | 可能沒有 | 失敗原因。3D 驗證開始後 10 分鐘沒完成是 `3DS_ABANDONED` |

### 範例

```json
{
  "purpose": "token",
  "merchantId": "ming",
  "id": "2HhngP9sVb3mK1xYdQe7Wc0RtUi",
  "transactionId": "2HhngP9sVb3mK1xYdQe7Wc0RtUi",
  "success": true,
  "token": "2HhnhWm8Qe0sPz4LbXv9KdYt1Ra",
  "paymentInfo": "4242",
  "customId": "M001",
  "message": ""
}
```

> 警告
> 
> 沒有 API 可以回查 token。這則通知沒收到，token 就拿不回來，只能請消費者重新綁卡。請確認你的接收端穩定，並在 10 秒內回應 2xx。

## schedule_subscription

[建立預約定期定額](../checkout-schedule.md)後，消費者在結帳頁完成或失敗時送出。之後每一期的扣款結果以 `charge` 通知送出。

| 欄位 | 型別 | 出現 | 說明 |
| --- | --- | --- | --- |
| `purpose` | `string` | 一定有 | `schedule_subscription` |
| `id` | `string` | 一定有 | 建立時回傳的 `id` |
| `subscriptionId` | `string` | 一定有 | 定期定額編號（`S` 開頭） |
| `merchantId` | `string` | 一定有 | 你的網域名稱 |
| `success` | `boolean` | 一定有 | 是否成功 |
| `amount` | `number` | 可能沒有 | 每期金額 |
| `currency` | `string` | 可能沒有 | 幣別（小寫） |
| `period` | `integer` | 可能沒有 | 已扣期數 |
| `numberOfPeriods` | `integer` | 可能沒有 | 總期數 |
| `interval` | `integer` | 可能沒有 | 每幾個月扣一次 |
| `startedAt` | `string` | 可能沒有 | 開始時間 |
| `nextChargeAt` | `string` | 可能沒有 | 下次扣款時間 |
| `paymentInfo` | `string` | 可能沒有 | 成功時為卡號末四碼 |
| `customId` | `string` | 可能沒有 | 你帶入的自訂資料 |
| `productDetails` | `array` | 可能沒有 | 商品明細 |
| `message` | `string` | 可能沒有 | 失敗原因 |

### 範例

```json
{
  "purpose": "schedule_subscription",
  "merchantId": "ming",
  "id": "2HhnfZ1kqRmA7cX0TQwq8vBn3Ls",
  "subscriptionId": "S20260928EF56GH78",
  "success": true,
  "amount": 1500,
  "currency": "twd",
  "period": 0,
  "numberOfPeriods": 4,
  "interval": 3,
  "startedAt": "2026-10-15T00:00:00.000Z",
  "nextChargeAt": "2026-10-15T01:00:00.000Z",
  "paymentInfo": "4242",
  "message": ""
}
```

## refund（需開啟）

| 欄位 | 說明 |
| --- | --- |
| `purpose` | `refund` |
| `id` | 這則退款事件的 id，每則都不同 |
| `refundId` | 退款單 id |
| `chargeId`、`chargeHumanId` | 原交易的內部 id 與交易編號（`P` 開頭） |
| `amount`、`origAmount` | 退款金額、原交易金額 |
| `currency` | 幣別（小寫） |
| `refundStatus` | `refunding`（處理中）、`refunded`（完成）、`cancelled`（取消） |
| `reason` | 退款原因 |
| `paymentMethod` | 原交易的付款方式 |
| `requestedAt`、`resolvedAt` | 申請時間、完成時間 |
| `customId` | 原交易的自訂資料 |
| `subscriptionId`、`period` | 定期定額交易才有 |

## subscription_cancelled（需開啟）

| 欄位 | 說明 |
| --- | --- |
| `purpose` | `subscription_cancelled` |
| `subscriptionId` | 定期定額編號 |
| `source` | 誰取消的：`merchant_api`（API）或 `crm`（後台） |
| `reason` | 取消原因 |
| `cancelledAt` | 取消時間 |
| `cancelledFromStatus` | 取消前的狀態 |
| `period`、`numberOfPeriods` | 已扣期數、總期數 |
| `customId` | 自訂資料 |

## subscription_retry（需開啟）

| 欄位 | 說明 |
| --- | --- |
| `purpose` | `subscription_retry` |
| `outcome` | `scheduled`：已排定重新扣款；`exhausted`：重扣次數用完，定期定額停止 |
| `retryAttemptNumber` | 第幾次重扣 |
| `nextRetryAt` | 下次重扣時間（`scheduled` 才有） |
| `failureCode` | 扣款失敗的原因 |
| `chargeId`、`chargeHumanId` | 失敗那一期的交易 |
| `subscriptionId`、`period` | 定期定額編號與期數 |
