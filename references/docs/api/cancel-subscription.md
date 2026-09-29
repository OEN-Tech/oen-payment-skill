---
title: "取消定期定額"
url: "https://developer.oen.tw/api/cancel-subscription/"
---

> 來源：https://developer.oen.tw/api/cancel-subscription/（自動產生，請勿手動修改）

# 取消定期定額

PUT `/subscriptions/:subscriptionHid`

-   正式環境：`https://payment-api.oen.tw/subscriptions/:subscriptionHid`
-   測試環境：`https://payment-api.testing.oen.tw/subscriptions/:subscriptionHid`

取消一筆 Payment API 定期定額，之後不會再扣款。只能取消進行中、已排程、扣款失敗待重扣的定期定額。**請一定要送 body**，至少帶 `merchantId`。

Header 帶 `Authorization: Bearer <token>` 與 `Content-Type: application/json` 。token 的取得方式見[驗證與 token](../developers/authentication.md)。

## 請求

### 路徑參數

| 欄位 | 型別 | 必填 | 說明 |
| --- | --- | --- | --- |
| `subscriptionHid` | `string` | 必填 | `S` 開頭的定期定額編號（17 字元）。不接受內部 id。 |

### Body 欄位

| 欄位 | 型別 | 必填 | 說明 |
| --- | --- | --- | --- |
| `merchantId` | `string` | 必填 | 你的網域名稱。例如應援頁是 `https://ming.oen.tw`，就填 `ming`。必須與 token 所屬的網域相同，不同會回 400 `V0001`。 範例：`ming` |
| `reason` | `string` | 選填 | 取消原因。 |

### 請求範例

範例一律打測試環境。把 `OEN_API_TOKEN` 設成測試環境 CRM 產生的 token。

終端機視窗

```bash
curl -X PUT "https://payment-api.testing.oen.tw/subscriptions/S20260928EF56GH78" \
  -H "Authorization: Bearer $OEN_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
  "merchantId": "ming",
  "reason": "會員申請取消"
}'
```

```js
const res = await fetch("https://payment-api.testing.oen.tw/subscriptions/S20260928EF56GH78", {
  method: "PUT",
  headers: {
    Authorization: `Bearer ${process.env.OEN_API_TOKEN}`,
    "Content-Type": "application/json",
  },
  body: JSON.stringify({
    "merchantId": "ming",
    "reason": "會員申請取消"
  }),
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
    CURLOPT_CUSTOMREQUEST => 'PUT',
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_HTTPHEADER => [
        'Authorization: Bearer ' . getenv('OEN_API_TOKEN'),
        'Content-Type: application/json',
    ],
    CURLOPT_POSTFIELDS => json_encode([
        'merchantId' => 'ming',
        'reason' => '會員申請取消',
    ]),
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
    "PUT",
    "https://payment-api.testing.oen.tw/subscriptions/S20260928EF56GH78",
    headers={"Authorization": f"Bearer {os.environ['OEN_API_TOKEN']}"},
    json={
        "merchantId": "ming",
        "reason": "會員申請取消",
    },
    timeout=30,
)

result = res.json()
if result["code"] != "S0000":
    raise RuntimeError(f"{result['code']} {result['message']}")
```

## 回應

| HTTP | 說明 |
| --- | --- |
| `200` | 取消成功，回傳更新後的定期定額 |
| `400` | 找不到，或目前狀態不能取消 |
| `401` | token 錯誤 |

### 回應範例

```json
{
  "code": "S0000",
  "data": {
    "id": "S20260928EF56GH78",
    "status": "cancelled",
    "period": 1,
    "paymentInterval": 1,
    "startedAt": "2026-09-28T02:31:46.640Z",
    "cancelledAt": "2026-09-28T02:35:00.000Z",
    "reason": "會員申請取消",
    "createdAt": "2026-09-28T02:31:46.640Z"
  },
  "message": ""
}
```

## 可能的錯誤

| 錯誤碼 | HTTP | 什麼時候會發生 |
| --- | --- | --- |
| `V0001` | 400 | 找不到定期定額、不屬於你的網域，或用了內部 id |
| `V0002` | 400 | 目前狀態不能取消（例如消費者還沒完成結帳、已取消、已完成、已停止），或取消當下剛好在扣款 |
| `A0001` | 401 | token 錯誤 |

完整清單與處理方式見[錯誤碼一覽](error-codes.md)。

## 相關說明

消費者提出取消時就應該取消，見[定期定額](../developers/subscriptions.md)。
