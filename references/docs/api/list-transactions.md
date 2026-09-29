---
title: "查詢交易列表"
url: "https://developer.oen.tw/api/list-transactions/"
---

> 來源：https://developer.oen.tw/api/list-transactions/（自動產生，請勿手動修改）

# 查詢交易列表

GET `/transactions`

-   正式環境：`https://payment-api.oen.tw/transactions`
-   測試環境：`https://payment-api.testing.oen.tw/transactions`

依建立時間由新到舊列出交易，每頁 50 筆。**列出的是網域的所有款項**，除了 API 建立的交易，也包含商店訂單、捐款等其他收款，以及撥款後退款產生的負數調整款項。只要 API 交易時，請用 `orderId` 比對，或改用[用訂單編號查詢](list-order-transactions.md)。

Header 帶 `Authorization: Bearer <token>` 。token 的取得方式見[驗證與 token](../developers/authentication.md)。

## 請求

### 查詢參數

| 欄位 | 型別 | 必填 | 說明 |
| --- | --- | --- | --- |
| `start` | `string` | 選填 | 起始日期，以台北時間的當天 00:00 起算。可以寫 `2026-09-01`，或 Unix 毫秒時間戳。 限制：要和 `end` 一起帶；只帶一個會回 500 `F0001`（`Invalid date`） |
| `end` | `string` | 選填 | 結束日期，算到台北時間的當天 23:59:59。 |
| `page` | `string` | 選填 | 下一頁的分頁標記。把上一頁回應的 `page` 原封不動帶入。 |

### 請求範例

範例一律打測試環境。把 `OEN_API_TOKEN` 設成測試環境 CRM 產生的 token。

終端機視窗

```bash
curl -X GET "https://payment-api.testing.oen.tw/transactions?start=2026-09-01&end=2026-09-28" \
  -H "Authorization: Bearer $OEN_API_TOKEN"
```

```js
const res = await fetch("https://payment-api.testing.oen.tw/transactions?start=2026-09-01&end=2026-09-28", {
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
$ch = curl_init('https://payment-api.testing.oen.tw/transactions?start=2026-09-01&end=2026-09-28');
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
    "https://payment-api.testing.oen.tw/transactions?start=2026-09-01&end=2026-09-28",
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
| `200` | 回傳交易列表與下一頁代碼 |
| `401` | token 錯誤 |
| `500` | 日期格式錯誤或 `page` 分頁標記無效（`F0001`） |

### 回應欄位

| 欄位 | 型別 | 出現 | 說明 |
| --- | --- | --- | --- |
| `transactions` | `array<Transaction>` | 一定有 | [Transaction 物件](objects/transaction.md)的陣列，不含 `productDetails` |
| `page` | `string \| null` | 一定有 | 下一頁的分頁標記；沒有下一頁時是 `null` |

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
    ],
    "page": "eyJMaW1pdCI6NTAsIkxhc3RFdmFsdWF0ZWRLZXkiOnt9fQ=="
  },
  "message": ""
}
```

## 可能的錯誤

| 錯誤碼 | HTTP | 什麼時候會發生 |
| --- | --- | --- |
| `F0001` | 500 | `start`、`end` 只帶一個或格式錯誤；`page` 分頁標記無效 |
| `A0001` | 401 | token 錯誤 |

完整清單與處理方式見[錯誤碼一覽](error-codes.md)。

## 相關說明

對帳做法見[查詢與對帳](../developers/querying.md)。
