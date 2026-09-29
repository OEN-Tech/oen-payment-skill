---
title: "用訂單編號查詢交易"
url: "https://developer.oen.tw/api/list-order-transactions/"
---

> 來源：https://developer.oen.tw/api/list-order-transactions/（自動產生，請勿手動修改）

# 用訂單編號查詢交易

GET `/order/:orderId/transactions`

-   正式環境：`https://payment-api.oen.tw/order/:orderId/transactions`
-   測試環境：`https://payment-api.testing.oen.tw/order/:orderId/transactions`

列出同一個 `orderId` 的所有 API 交易，包含失敗的交易與定期定額每一期。一次回傳全部，不分頁，也不保證順序。消費者重試付款、或結帳頁過期後重新建立時，一個訂單可能有多筆交易，請用這支確認有沒有成功的那一筆。

Header 帶 `Authorization: Bearer <token>` 。token 的取得方式見[驗證與 token](../developers/authentication.md)。

## 請求

### 路徑參數

| 欄位 | 型別 | 必填 | 說明 |
| --- | --- | --- | --- |
| `orderId` | `string` | 必填 | 建立交易時帶的 `orderId`。 |

### 請求範例

範例一律打測試環境。把 `OEN_API_TOKEN` 設成測試環境 CRM 產生的 token。

終端機視窗

```bash
curl -X GET "https://payment-api.testing.oen.tw/order/A20260928001/transactions" \
  -H "Authorization: Bearer $OEN_API_TOKEN"
```

```js
const res = await fetch("https://payment-api.testing.oen.tw/order/A20260928001/transactions", {
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
$ch = curl_init('https://payment-api.testing.oen.tw/order/A20260928001/transactions');
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
    "https://payment-api.testing.oen.tw/order/A20260928001/transactions",
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
| `200` | 回傳交易陣列。查無資料時是空陣列 |
| `401` | token 錯誤 |

### 回應欄位

| 欄位 | 型別 | 出現 | 說明 |
| --- | --- | --- | --- |
| `transactions` | `array<Transaction>` | 一定有 | [Transaction 物件](objects/transaction.md)的陣列，不含 `productDetails` |

### 回應範例

```json
{
  "code": "S0000",
  "data": {
    "transactions": [
      {
        "id": "P20260928AB12CD34",
        "transactionId": "2HhndgEquCbDzC5OyVxWSGZmd2l",
        "action": "onetime",
        "amount": 1200,
        "paymentMethod": "card",
        "status": "charged",
        "orderId": "A20260928001",
        "createdAt": "2026-09-28T02:40:25.502Z",
        "paidAt": "2026-09-28T02:41:03.118Z",
        "refundAmount": 0
      }
    ]
  },
  "message": ""
}
```

## 可能的錯誤

| 錯誤碼 | HTTP | 什麼時候會發生 |
| --- | --- | --- |
| `A0001` | 401 | token 錯誤 |

完整清單與處理方式見[錯誤碼一覽](error-codes.md)。

## 相關說明

什麼時候會有多筆，見[查詢與對帳](../developers/querying.md)。
