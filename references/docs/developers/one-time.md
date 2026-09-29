---
title: "單次付款"
url: "https://developers.oentech.ai/developers/one-time/"
---

> 來源：https://developers.oentech.ai/developers/one-time/（自動產生，請勿手動修改）

# 單次付款

## 流程

1.  消費者在你的網站按下「付款」。
2.  你的伺服器呼叫 [`POST /checkout`](../api/checkout.md)，拿到 `id` 與 `transactionHid`，存進訂單。
3.  把消費者導到 `https://{網域名稱}.oen.tw/checkout/{id}`。
4.  消費者在應援結帳頁選擇付款方式並付款。
5.  應援送出[付款通知](webhooks.md)到你的伺服器，你用 [`GET /transactions/{id}`](../api/get-transaction.md) 回查後更新訂單。
6.  消費者被導回 `successUrl` 或 `failureUrl`。

## 建立結帳的重點

-   **`productDetails` 必填**，各品項「數量 × 單價」的合計必須等於 `amount`。有折扣或運費時，請調整品項（例如把折扣攤進單價、把運費列成一個品項），讓合計等於實付金額。
-   **金額是新台幣整數**。`currency` 可以不帶，預設就是 `TWD`。
-   **網址自己組**：回應只有 `id`，結帳頁是 `https://{網域名稱}.oen.tw/checkout/{id}`，測試環境是 `{網域名稱}.testing.oen.tw`。
-   **沒有的欄位會被忽略**：例如 `webhookUrl`、`cancelUrl` 都不是 Payment API 的欄位，送了也不會有效果。付款通知網址在 CRM 設定。

完整欄位見 [API 參考](../api/checkout.md)。

## 結帳頁 5 分鐘內有效

結帳頁從你呼叫 `POST /checkout` 的那一刻起算，**5 分鐘**內有效：

-   消費者停在結帳頁、倒數到 0 時，會看到「付款時限已過」，8 秒後被導回 `failureUrl?payment_error=V0002`。
-   過期後才打開連結，會看到「此付款連結資訊已過期」，**不會**導回你的網站。

所以請在消費者真的要付款時才建立，建立後立刻導過去。不要先建好連結再用 email 或訊息寄給消費者。

> 5 分鐘後結果仍可能改變
> 
> 5 分鐘只限制「打開結帳頁」。消費者在時限內送出付款後，3D 驗證、LINE Pay 確認、超商或 ATM 繳費的結果，都可能在 5 分鐘之後才確定。不要在 5 分鐘到的時候就把訂單判定為失敗、之後又不接受成功的通知。

## 消費者要重新付款

消費者付款失敗、逾時或改變心意時，重新呼叫 `POST /checkout` 建立新的交易即可：

-   **同一個 `orderId` 可以建立多筆交易**，應援不會擋。
-   每一筆都是獨立的交易，有自己的 `id`。
-   極少數情況下，消費者可能在兩個結帳頁都完成付款。請用 [`GET /order/{orderId}/transactions`](../api/list-order-transactions.md) 檢查同一個訂單有幾筆成功，多的那筆請[退款](refunds.md)。

## 消費者放棄付款

消費者沒有付款、直接離開時，**應援不會送任何通知**，交易會一直停在 `initiated`。請在你的系統自行處理，例如：

-   建立後 30 分鐘仍沒有結果的訂單，先用[訂單編號查詢](../api/list-order-transactions.md)確認沒有成功或處理中的交易，再把訂單標為未付款。
-   查到 `charging`（超商、ATM 等待繳費，或 LINE Pay 等待確認）時，繼續等待。

## 判斷付款結果

| 你看到的 | 意思 | 怎麼做 |
| --- | --- | --- |
| `status` 是 `charged` 或 `claimed` | 付款成功 | 出貨 |
| `status` 是 `charging` | 處理中：超商、ATM 已取號等待繳費；LINE Pay 等待確認 | 等下一則通知 |
| `status` 是 `failed` | 付款失敗或逾期未繳 | 讓消費者重新付款 |
| `status` 是 `initiated` | 消費者還沒送出付款 | 等待，或視為放棄 |

一律以[回查](../api/get-transaction.md)的結果為準，不要只看付款通知或導回網址。

## 導回網址

-   **成功**：導回 `successUrl`，**不帶任何參數**。請在網址放自己的訂單編號，例如 `?order=A001`，頁面再到你的後端查訂單狀態。
-   **失敗**：導回 `failureUrl`，加上 `payment_error`，可能的值見[錯誤碼一覽](../api/error-codes.md#%E7%B5%90%E5%B8%B3%E9%A0%81%E5%B0%8E%E5%9B%9E%E7%9A%84-payment_error)。`#` 之後的片段會被拿掉。
-   **超商代碼、ATM**：消費者取號後停在應援的繳費資訊頁，按「返回網站」才回到 `successUrl`。
-   **LINE Pay**：失敗或取消時導回 `failureUrl`，不帶 `payment_error`。

> failureUrl 不要自帶參數
> 
> 部分 3D 驗證失敗的情況，會直接在 `failureUrl` 後面接上 `?payment_error=T0001`。`failureUrl` 原本就有 `?` 時，網址會變成兩個 `?`。請讓 `failureUrl` 用路徑帶訂單編號，例如 `https://shop.example.com/payment/failure/A001`。

## 付款方式

用 `allowedPaymentMethods` 加開超商代碼、LINE Pay、ATM。**信用卡一定會出現**，Apple Pay 條件符合時自動出現。詳見[付款方式](payment-methods.md)。

## 3D 驗證

-   `use3d: true` 時，信用卡付款會走 3D 驗證。預設是 `false`。
-   應援可以把你的網域設定為一律 3D，這時不管帶什麼都會走 3D。
-   3D 驗證開始後 10 分鐘沒有完成，交易會變成失敗，並送出 `message` 為 `3DS_ABANDONED` 的付款通知。
-   Apple Pay 不走 3D 驗證。

## 電子發票

網域開通「應援代開電子發票」後，付款成功會自動開立發票：

-   `userName` 與 `userEmail` 變成必填，發票通知寄到 `userEmail`。
-   發票品項來自 `productDetails`。
-   要開手機條碼、自然人憑證或公司戶發票，帶 `invoiceInfo`：

```json
{
  "invoiceInfo": { "invoiceType": "cloud", "carrierType": "3J0002", "carrierId": "/ABC+123" }
}
```

```json
{
  "invoiceInfo": { "invoiceType": "company", "buyerIdentifier": "12345675", "buyerName": "應援範例股份有限公司" }
}
```

手機條碼會即時向財政部驗證，不存在的條碼會回 400 `V0001`（`INVALID_CARRIER_ID`）；統一編號會檢查檢查碼（`INVALID_TAX_ID_NUMBER`）。沒帶 `invoiceInfo` 時開立雲端發票。

## 帶上你自己的資料

-   `customId`：原樣出現在付款通知與查詢結果，適合放購物車編號等資料。
-   `userId`：你系統裡的會員編號，會出現在查詢結果與 CRM。
-   `note`：備註，會出現在 CRM 金流明細。
