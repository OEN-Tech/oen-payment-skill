---
title: "Transaction 物件"
url: "https://developer.oen.tw/api/objects/transaction/"
---

> 來源：https://developer.oen.tw/api/objects/transaction/（自動產生，請勿手動修改）

# Transaction 物件

查詢交易、交易列表、用訂單編號查詢與退款的回應都用這個物件。沒有值的欄位不會出現。

| 欄位 | 型別 | 出現 | 說明 |
| --- | --- | --- | --- |
| `id` | `string` | 一定有 | 交易編號。API 交易是 `P` 開頭共 17 字元；交易列表裡其他來源的款項是 `C` 開頭 |
| `transactionId` | `string` | 一定有 | 交易的內部 id（27 字元），和付款通知的 `id` 相同 |
| `action` | `string` | 可能沒有 | `onetime` 單次、`subscription` 定期定額 |
| `amount` | `number` | 一定有 | 金額。交易列表中的負數是撥款後退款產生的調整款項 |
| `fee` | `number` | 可能沒有 | 手續費 |
| `platformFee` | `number` | 可能沒有 | 平台費 |
| `paymentMethod` | `string` | 可能沒有 | `card`、`applePay`、`linePay`、`cvs`、`atm` |
| `paymentInfo` | `object` | 可能沒有 | 付款方式的細節，依付款方式不同，見下方說明 |
| `status` | `string` | 一定有 | 交易狀態，見下方狀態表 |
| `orderId` | `string` | 可能沒有 | 你的訂單編號 |
| `userId` | `string` | 可能沒有 | 你帶入的會員編號 |
| `userName` | `string` | 可能沒有 | 消費者姓名 |
| `userEmail` | `string` | 可能沒有 | 消費者 Email |
| `customId` | `string` | 可能沒有 | 你帶入的自訂資料 |
| `note` | `string` | 可能沒有 | 備註 |
| `reason` | `string` | 可能沒有 | 付款失敗的原因（收單機構回傳的原始訊息） |
| `authCode` | `string` | 可能沒有 | 信用卡授權碼 |
| `use3d` | `boolean` | 可能沒有 | 是否走了 3D 驗證 |
| `createdAt` | `string` | 一定有 | 建立時間（UTC，ISO 8601） |
| `paidAt` | `string` | 可能沒有 | 付款完成時間 |
| `refundAmount` | `number` | 可能沒有 | 已退款金額，預設 0 |
| `refundedAt` | `string` | 可能沒有 | 退款時間 |
| `payoutId` | `string` | 可能沒有 | 撥款單 id |
| `payoutAt` | `string` | 可能沒有 | 撥款時間 |
| `subscriptionId` | `string` | 可能沒有 | 所屬定期定額的編號（`S` 開頭），定期定額交易才有 |
| `period` | `integer` | 可能沒有 | 定期定額的第幾期 |
| `productDetails` | `array` | 可能沒有 | 商品明細。只在[查詢交易明細](../get-transaction.md)並以內部 id 查詢時出現 |
| `numberOfPeriods` | `integer` | 可能沒有 | 定期定額總期數（0 為不限期）。出現條件同 `productDetails` |
| `success` | `boolean` | 可能沒有 | 只在退款回應中出現 |

### 範例

```json
{
  "id": "P20260928AB12CD34",
  "transactionId": "2HhndgEquCbDzC5OyVxWSGZmd2l",
  "action": "onetime",
  "amount": 1200,
  "paymentMethod": "card",
  "paymentInfo": {
    "method": "card",
    "cardNum": "424242******4242",
    "cardName": "WANG XIAO MING",
    "cardType": "Visa",
    "cardIssuerCountry": "TW"
  },
  "status": "charged",
  "orderId": "A20260928001",
  "userName": "王小明",
  "userEmail": "ming@example.com",
  "createdAt": "2026-09-28T02:40:25.502Z",
  "paidAt": "2026-09-28T02:41:03.118Z",
  "refundAmount": 0,
  "authCode": "831000"
}
```

## paymentInfo

依付款方式不同：

| 付款方式 | 內容 |
| --- | --- |
| 信用卡 | `method`、`cardNum`（遮罩為前 6 碼與後 4 碼，例如 `424242******4242`）、`cardName`、`cardType`（Visa、MasterCard、JCB 等）、`cardIssuerCountry` |
| 用 token 扣款的信用卡 | 只有 `{ "method": "card" }` |
| 超商代碼 | `method`、`cvsCode`、`cvsName`、`totalAmount`、`expiredAt`，以及 `credentials: { cvsName, code, expiredAt }` |
| ATM | `method`、`bankName`、`bankCode`、`account`（虛擬帳號）、`expiredAt` 等 |
| LINE Pay | `method`、`transactionId`（LINE Pay 交易編號）等 |

程式請只讀上表列出的欄位，其他欄位可能調整。

## 交易狀態

| status | 意思 | 在 CRM 顯示為 |
| --- | --- | --- |
| `initiated` | 已建立，消費者還沒付款。消費者離開結帳頁時會一直停在這個狀態，不會變成失敗 | 已建立付款意向 |
| `charging` | 處理中。超商代碼、ATM 已取號等待繳費；LINE Pay 等待確認；付款結果不明時也停在這裡 | 尚未付款 |
| `authorized` | 已授權、尚未請款（高額交易） | 已授權 |
| `charged` | 付款成功，款項由應援代收、等待撥款 | 付款成功 |
| `claimed` | 付款成功且款項已撥給你；LINE Pay、藍新等由收單機構直接撥款的付款方式，付款成功就是這個狀態 | 已入帳 |
| `failed` | 付款失敗或逾期未繳 | 扣款或授權失敗、已失效 |
| `cancelled` | 已取消（尚未繳費的超商代碼被取消） | 已取消 |
| `refunding` | 退款處理中（已付款的超商代碼、ATM 等待匯款） | 退款中 |
| `refunded` | 已退款。`refundAmount` 小於 `amount` 時是部分退款 | 全額退款、部分退款 |
| `refundedPostPayout` | 撥款後才退款，會從下次撥款扣回 | 撥款後退款 |

判斷「付款成功」請用 `charged` 或 `claimed`，不要只看 `charged`。`authorized` 只會出現在需要審核的高額交易，遇到時請聯絡應援確認後續流程。
