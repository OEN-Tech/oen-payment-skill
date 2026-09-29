---
title: "查詢定期定額明細"
url: "https://developers.oentech.ai/api/get-subscription/"
---

> 來源：https://developers.oentech.ai/api/get-subscription/（自動產生，請勿手動修改）

# 查詢定期定額明細

GET `/subscriptions/:id`

-   正式環境：`https://payment-api.oen.tw/subscriptions/:id`
-   測試環境：`https://payment-api.testing.oen.tw/subscriptions/:id`

查詢一筆 Payment API 定期定額的狀態、期數與下次扣款時間。

Header 帶 `Authorization: Bearer <token>` 。token 的取得方式見[驗證與 token](../developers/authentication.md)。

## 請求

### 路徑參數

| 欄位 | 型別 | 必填 | 說明 |
| --- | --- | --- | --- |
| `id` | `string` | 必填 | `S` 開頭的定期定額編號，或定期定額的內部 id。 |

### 請求範例

範例一律打測試環境。把 `OEN_API_TOKEN` 設成測試環境 CRM 產生的 token。

終端機視窗

```bash
curl -X GET "https://payment-api.testing.oen.tw/subscriptions/S20260928EF56GH78" \
  -H "Authorization: Bearer $OEN_API_TOKEN"
```

```js
const res = await fetch("https://payment-api.testing.oen.tw/subscriptions/S20260928EF56GH78", {
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
$ch = curl_init('https://payment-api.testing.oen.tw/subscriptions/S20260928EF56GH78');
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
    "https://payment-api.testing.oen.tw/subscriptions/S20260928EF56GH78",
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
| `200` | 回傳 [Subscription 物件](objects/subscription.md) |
| `400` | 找不到，或不屬於你的網域（`V0001`） |
| `401` | token 錯誤 |

### 回應範例

```json
{
  "code": "S0000",
  "data": {
    "id": "S20260928EF56GH78",
    "status": "ongoing",
    "period": 1,
    "numberOfPeriods": 12,
    "paymentInterval": 1,
    "startedAt": "2026-09-28T02:44:35.592Z",
    "endedAt": "2027-08-28T02:44:35.592Z",
    "nextChargeAt": "2026-10-28T01:00:00.000Z",
    "createdAt": "2026-09-28T02:44:35.592Z",
    "amount": 299,
    "userName": "王小明",
    "orderId": "SUB20260928001"
  },
  "message": ""
}
```

## 可能的錯誤

| 錯誤碼 | HTTP | 什麼時候會發生 |
| --- | --- | --- |
| `V0001` | 400 | 找不到定期定額，或不屬於你的網域 |
| `A0001` | 401 | token 錯誤 |

完整清單與處理方式見[錯誤碼一覽](error-codes.md)。

## 相關說明

狀態說明見 [Subscription 物件](objects/subscription.md)。
