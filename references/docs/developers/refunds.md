---
title: "退款"
url: "https://developers.oentech.ai/developers/refunds/"
---

> 來源：https://developers.oentech.ai/developers/refunds/（自動產生，請勿手動修改）

# 退款

用 [`POST /refunds/{transactionHid}`](../api/refund.md) 退款。路徑要用 `P` 開頭的交易編號，不是 27 字元的 `id`。

> 每筆交易只能退一次
> 
> 不論用 API 或 CRM，每筆交易都只能成功退款一次。部分退款之後，剩下的金額不能再退。請一次決定好金額。

## 可以退的交易

交易狀態必須是 `charged` 或 `claimed`，而且還沒退過款。

| 原付款方式 | 怎麼退 | 要帶 `remitInfo` 嗎 | 退款後的狀態 |
| --- | --- | --- | --- |
| 信用卡、Apple Pay | 即時退回卡片 | 不用 | `refunded`；已撥款的是 `refundedPostPayout` |
| LINE Pay | 即時退回 LINE Pay | 不用 | `refunded` |
| 超商代碼、ATM（已繳費） | 由應援匯款到消費者的帳戶 | **要** | `refunding`，匯款完成後更新 |
| 超商代碼（還沒繳費） | 取消繳費代碼 | 不用 | `cancelled` |

-   `amount` 不帶就是全額退款；有帶就是部分退款，不能大於原金額。
-   退款成功時，回應的 `status` 已經是新的狀態，`refundAmount` 是這次退款的金額（超商、ATM 要等匯款完成才更新）。

## 超商代碼與 ATM

已繳費的交易要帶消費者的銀行帳戶：

```json
{
  "merchantId": "ming",
  "reason": "商品缺貨",
  "remitInfo": {
    "bankCode": "004",
    "bankName": "臺灣銀行",
    "branchCode": "0037",
    "branchName": "營業部",
    "account": "12345678901234",
    "accountName": "王小明"
  }
}
```

-   6 個欄位都必填；`account` 是 8 到 14 字元。
-   退款會停在 `refunding`，由應援處理匯款。

## 有開電子發票的交易

原交易有開電子發票時：

-   **`productDetails` 必填**，品項合計必須等於這次的退款金額，用來開立折讓。
-   信用卡與 LINE Pay 退款成功後，系統會自動開立折讓。
-   發票還沒開出就全額退款時，系統直接取消待開的發票。

```json
{
  "merchantId": "ming",
  "amount": 600,
  "reason": "消費者取消一包",
  "productDetails": [
    { "productionCode": "SKU-001", "description": "手沖咖啡豆 200g", "quantity": 1, "unit": "包", "unitPrice": 600 }
  ]
}
```

## 退款失敗

| 你收到 | 意思 | 怎麼做 |
| --- | --- | --- |
| 400 `V0002` | 交易狀態不能退款：還沒付款、已經退過，或正在處理另一筆退款 | 用[查詢交易明細](../api/get-transaction.md)確認狀態 |
| 400 `R0001` | 收單機構拒絕退款 | 先查詢交易狀態。之後重試都回 `V0002` 時，代表退款結果需要人工確認，請聯絡應援 |
| 400 `V0001` `REMITTANCE_INFO_REQUIRED` | 已繳費的超商代碼或 ATM 沒帶 `remitInfo` | 補上退款帳戶 |
| 400 `V0001` `PRODUCT_DETAILS_REQUIRED` | 有開發票的交易沒帶 `productDetails` | 補上折讓品項 |
| 500 `F0001` `Current charged amount too low` | 你的網域尚未撥款的已收款金額低於 200 元，暫時無法退款 | 請聯絡應援 |
| 逾時、500 其他訊息 | 結果不明 | **不要直接重送**。先查詢交易的 `status` 與 `refundAmount` |

## 已撥款的交易

款項已經撥給商家後才退款，交易會變成 `refundedPostPayout`，退款金額與退款手續費會從下一次撥款扣除。

## 退款通知

退款不會送 `charge` 通知。要收到退款通知（`purpose: refund`），請應援為你的網域開啟「Webhook 新版事件」，欄位見[付款通知內容](../api/objects/webhook.md#refund%E9%9C%80%E9%96%8B%E5%95%9F)。

## 在 CRM 退款

商家也可以在 CRM 的金流明細退款，規則相同，見[商家指南的退款說明](https://developers.oentech.ai/merchant/refunds/)。
