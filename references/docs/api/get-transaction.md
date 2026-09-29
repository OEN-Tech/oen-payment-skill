---
title: "查詢交易明細"
url: "https://developer.oen.tw/api/get-transaction/"
---

> 來源：https://developer.oen.tw/api/get-transaction/（自動產生，請勿手動修改）

# 查詢交易明細

GET `/transactions/:id`

-   正式環境：`https://payment-api.oen.tw/transactions/:id`
-   測試環境：`https://payment-api.testing.oen.tw/transactions/:id`

查詢一筆交易的最新狀態。收到付款通知後，請用這支回查確認結果再出貨。**請用 27 字元的 `id` 查詢**；用 `P` 開頭的交易編號也查得到，但回應不會有 `productDetails` 與 `numberOfPeriods`。

Header 帶 `Authorization: Bearer <token>` 。token 的取得方式見[驗證與 token](../developers/authentication.md)。

## 請求

### 路徑參數

| 欄位 | 型別 | 必填 | 說明 |
| --- | --- | --- | --- |
| `id` | `string` | 必填 | 交易的內部 id（建立交易時回傳的 `id`，或付款通知裡的 `id`），也可以是 `P` 開頭的交易編號。 |

### 請求範例

範例一律打測試環境。把 `OEN_API_TOKEN` 設成測試環境 CRM 產生的 token。

終端機視窗

```bash
curl -X GET "https://payment-api.testing.oen.tw/transactions/2HhndgEquCbDzC5OyVxWSGZmd2l" \
  -H "Authorization: Bearer $OEN_API_TOKEN"
```

```js
const res = await fetch("https://payment-api.testing.oen.tw/transactions/2HhndgEquCbDzC5OyVxWSGZmd2l", {
  method: "GET",
  headers: {
    Authorization: `Bearer ${process.env.OEN_API_TOKEN}`,
  },
});

const result = await res.json();
if (result.code !== "S0000") {
  throw new Error(`${result.code} ${result.message}`);
}
```

```php
<?php
$ch = curl_init('https://payment-api.testing.oen.tw/transactions/2HhndgEquCbDzC5OyVxWSGZmd2l');
curl_setopt_array($ch, [
    CURLOPT_CUSTOMREQUEST => 'GET',
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_HTTPHEADER => [
        'Authorization: Bearer ' . getenv('OEN_API_TOKEN'),
    ],
]);

$result = json_decode(curl_exec($ch), true);
if ($result['code'] !== 'S0000') {
    throw new Exception($result['code'] . ' ' . $result['message']);
}
```

```python
import os
import requests

res = requests.request(
    "GET",
    "https://payment-api.testing.oen.tw/transactions/2HhndgEquCbDzC5OyVxWSGZmd2l",
    headers={"Authorization": f"Bearer {os.environ['OEN_API_TOKEN']}"},
    timeout=30,
)

result = res.json()
if result["code"] != "S0000":
    raise RuntimeError(f"{result['code']} {result['message']}")
```

## 回應

| HTTP | 說明 |
| --- | --- |
| `200` | 回傳 [Transaction 物件](objects/transaction.md) |
| `400` | 找不到交易，或交易不屬於你的網域（`V0001`） |
| `401` | token 錯誤 |

### 回應範例

```json
{
  "code": "S0000",
  "data": {
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
    "userName": "王小明",
    "userEmail": "ming@example.com",
    "orderId": "A20260928001",
    "createdAt": "2026-09-28T02:40:25.502Z",
    "paidAt": "2026-09-28T02:41:03.118Z",
    "refundAmount": 0,
    "authCode": "831000",
    "customId": "cart-8812",
    "use3d": false,
    "productDetails": [
      {
        "productionCode": "SKU-001",
        "description": "手沖咖啡豆 200g",
        "quantity": 2,
        "unit": "包",
        "unitPrice": 600
      }
    ]
  },
  "message": ""
}
```

## 可能的錯誤

| 錯誤碼 | HTTP | 什麼時候會發生 |
| --- | --- | --- |
| `V0001` | 400 | 找不到交易，或交易不屬於你的網域 |
| `A0001` | 401 | token 錯誤 |

完整清單與處理方式見[錯誤碼一覽](error-codes.md)。

## 相關說明

收到付款通知後怎麼回查，見[付款通知](../developers/webhooks.md)。欄位說明見 [Transaction 物件](objects/transaction.md)。
