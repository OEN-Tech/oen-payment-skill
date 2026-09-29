---
title: "存卡與後續扣款"
url: "https://developers.oentech.ai/developers/saved-cards/"
---

> 來源：https://developers.oentech.ai/developers/saved-cards/（自動產生，請勿手動修改）

# 存卡與後續扣款

存卡適合「金額或時間由你決定」的情境，例如儲值、按用量計費、一鍵回購。消費者只需要綁一次卡，之後由你的伺服器用 token 扣款，消費者不必在場。

## 流程

1.  你的伺服器呼叫 [`POST /checkout-token`](../api/checkout-token.md)，拿到 `id`。
2.  把消費者導到 `https://{網域名稱}.oen.tw/checkout/subscription/create/{id}`。**10 分鐘內有效。**
3.  消費者輸入卡片並完成 3D 驗證。
4.  應援送出 `purpose` 為 `token` 的[付款通知](../api/objects/webhook.md#token)，裡面有 `token`。把它存進這位會員的資料。
5.  消費者被導回 `successUrl`（**不帶 token**）。
6.  之後要扣款時，呼叫 [`POST /token/transactions`](../api/token-transactions.md) 或 [`POST /token/subscriptions`](../api/token-subscriptions.md)。

> token 只能從付款通知拿到
> 
> -   導回網址不帶 token，也**沒有 API 可以查詢 token**。
> -   付款通知最多送 3 次（間隔約 2 秒、4 秒），都失敗就不會再送，這個 token 就拿不回來，只能請消費者重新綁卡。
> -   請確認接收端穩定，並用 `customId` 帶上會員編號，收到通知時才知道是誰的卡。

## 綁卡頁

-   消費者一定要填 Email。建立時帶 `payerEmail` 可以預先填好。
-   部分收單機構綁卡時會**先授權新台幣 1 元再立即退回**，頁面會事先告知消費者，也可能要求填寫英文持卡人姓名。
-   逾時（10 分鐘）後導回 `failureUrl?payment_error=Y003`。
-   3D 驗證開始後 10 分鐘沒完成，會送出 `success: false`、`message: 3DS_ABANDONED` 的通知。

## token 的特性

| 特性 | 說明 |
| --- | --- |
| 有效期限 | 沒有期限。卡片本身過期後，扣款會被發卡銀行拒絕 |
| 同一張卡再綁一次 | 會得到**新的** token，舊的仍然可以用 |
| 刪除 | 沒有刪除 API。會員要求移除卡片時，請在你的系統刪除 token |
| 換卡 | 沒有更新卡片的 API。請消費者重新綁卡，換成新的 token |
| 保存 | token 可以直接扣款，請當成密碼一樣保存，不要傳到前端 |

## 用 token 扣款

終端機視窗

```bash
curl -X POST "https://payment-api.testing.oen.tw/token/transactions" \
  -H "Authorization: Bearer $OEN_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "merchantId": "ming",
    "amount": 1200,
    "token": "2HhnhWm8Qe0sPz4LbXv9KdYt1Ra",
    "orderId": "A20260928003",
    "productDetails": [
      { "productionCode": "SKU-001", "description": "手沖咖啡豆 200g", "quantity": 2, "unit": "包", "unitPrice": 600 }
    ]
  }'
```

-   不走 3D 驗證，**結果就是 API 回應**，不會送付款通知。
-   成功回傳 `id`（`P` 開頭的交易編號）與 `authCode`。
-   失敗回 400 與 `T0001`～`T0005`。失敗的交易也會建立，可以用訂單編號查到。
-   只能是新台幣，`amount` 必須是整數。
-   單筆 200,000 元以上需要網域開通高額交易，否則回 `V0003`。

> 不要直接重送
> 
> Payment API 沒有防重複扣款的機制：同樣的請求送兩次，就會扣兩次。遇到下列情況時，**先用[訂單編號查詢](../api/list-order-transactions.md)確認**，再決定要不要重送：
> 
> -   請求逾時，或收到 HTTP 504、500。
> -   收到 409 `C026`（付款結果不明）。這時請不要重送，稍後再查詢；久未確定請聯絡應援。

## 用 token 建立定期定額

[`POST /token/subscriptions`](../api/token-subscriptions.md) 用 token 建立定期定額，之後由應援自動扣款：

-   不帶 `startDate`：當下扣第一期，結果以回應為準；第一期失敗時定期定額不會成立。
-   帶未來日期：只建立排程（狀態 `scheduled`），**不會先驗證 token**，到期才扣款。

扣款時間與失敗處理見[定期定額](subscriptions.md)。
