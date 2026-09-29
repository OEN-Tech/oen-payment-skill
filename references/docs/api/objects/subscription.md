---
title: "Subscription 物件"
url: "https://developer.oen.tw/api/objects/subscription/"
---

> 來源：https://developer.oen.tw/api/objects/subscription/（自動產生，請勿手動修改）

# Subscription 物件

[查詢定期定額明細](../get-subscription.md)的回應。沒有值的欄位不會出現。

| 欄位 | 型別 | 出現 | 說明 |
| --- | --- | --- | --- |
| `id` | `string` | 一定有 | 定期定額編號（`S` 開頭，17 字元） |
| `status` | `string` | 一定有 | 狀態，見下方狀態表 |
| `period` | `integer` | 可能沒有 | 已扣期數 |
| `numberOfPeriods` | `integer` | 可能沒有 | 總期數。不限期時不會出現 |
| `paymentInterval` | `integer` | 可能沒有 | 每幾個月扣一次 |
| `amount` | `number` | 可能沒有 | 每期金額 |
| `startedAt` | `string` | 可能沒有 | 開始時間 |
| `endedAt` | `string` | 可能沒有 | 預計結束時間 |
| `nextChargeAt` | `string` | 可能沒有 | 下次扣款時間，只在 `ongoing` 時出現。固定是扣款日台北時間上午 9 點（例如 `2026-10-28T01:00:00.000Z`） |
| `cancelledAt` | `string` | 可能沒有 | 取消時間 |
| `reason` | `string` | 可能沒有 | 取消原因，或扣款失敗的原因 |
| `orderId` | `string` | 可能沒有 | 你的訂單編號 |
| `userId` | `string` | 可能沒有 | 你帶入的會員編號 |
| `userName` | `string` | 可能沒有 | 消費者姓名 |
| `note` | `string` | 可能沒有 | 備註 |
| `createdAt` | `string` | 一定有 | 建立時間 |

### 範例

```json
{
  "id": "S20260928EF56GH78",
  "status": "ongoing",
  "period": 1,
  "numberOfPeriods": 12,
  "paymentInterval": 1,
  "amount": 299,
  "startedAt": "2026-09-28T02:44:35.592Z",
  "endedAt": "2027-08-28T02:44:35.592Z",
  "nextChargeAt": "2026-10-28T01:00:00.000Z",
  "orderId": "SUB20260928001",
  "userName": "王小明",
  "createdAt": "2026-09-28T02:44:35.592Z"
}
```

## 定期定額狀態

| status | 意思 | 在 CRM 顯示為 |
| --- | --- | --- |
| `initiated` | 已建立，消費者還沒完成結帳 | — |
| `processing` | 消費者正在結帳（例如 3D 驗證中） | — |
| `scheduled` | 首期日在未來，已完成綁卡，等待首期扣款 | — |
| `ongoing` | 進行中 | 進行中 |
| `retryScheduled` | 這一期扣款失敗，已排定重新扣款 | 異常 - 待重扣 |
| `error` | 扣款失敗且不再重試，**之後的期數都不會再扣款** | 異常 |
| `cancelled` | 已取消，或已到結束日 | 已取消 |
| `done` | 所有期數都扣完了 | 已結束 |

`trialing`、`terminated` 只會出現在 [Subscription API](../../products/subscription-api.md) 建立的訂閱。

可以取消的狀態：`scheduled`、`ongoing`、`retryScheduled`。見[取消定期定額](../cancel-subscription.md)。
