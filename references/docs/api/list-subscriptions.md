---
title: "查詢商店定期購訂單列表"
url: "https://developers.oentech.ai/api/list-subscriptions/"
---

> 來源：https://developers.oentech.ai/api/list-subscriptions/（自動產生，請勿手動修改）

# 查詢商店定期購訂單列表

GET `/subscriptions`

-   正式環境：`https://payment-api.oen.tw/subscriptions`
-   測試環境：`https://payment-api.testing.oen.tw/subscriptions`

**列出的是應援商店的「定期購」訂單**，不是用 Payment API 建立的定期定額。只有在應援商店販售訂閱制商品的商家才需要。Payment API 定期定額請用[查詢定期定額明細](get-subscription.md)。依建立時間由新到舊，每頁最多 50 筆；用 `status` 篩選時，一頁可能少於 50 筆但仍有下一頁。

Header 帶 `Authorization: Bearer <token>` 。token 的取得方式見[驗證與 token](../developers/authentication.md)。

## 請求

### 查詢參數

| 欄位 | 型別 | 必填 | 說明 |
| --- | --- | --- | --- |
| `status` | `string` | 選填 | 用逗號分隔的狀態。不帶就是全部。 可用值：`ongoing`、`cancelled`、`done`、`error`、`retryScheduled` 範例：`ongoing,retryScheduled` |
| `page` | `string` | 選填 | 下一頁的分頁標記。把上一頁回應的 `page` 原封不動帶入。 |

### 請求範例

範例一律打測試環境。把 `OEN_API_TOKEN` 設成測試環境 CRM 產生的 token。

終端機視窗

```bash
curl -X GET "https://payment-api.testing.oen.tw/subscriptions?status=ongoing" \
  -H "Authorization: Bearer $OEN_API_TOKEN"
```

```js
const res = await fetch("https://payment-api.testing.oen.tw/subscriptions?status=ongoing", {
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
$ch = curl_init('https://payment-api.testing.oen.tw/subscriptions?status=ongoing');
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
    "https://payment-api.testing.oen.tw/subscriptions?status=ongoing",
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
| `200` | 回傳定期購訂單列表與下一頁代碼 |
| `401` | token 錯誤 |

### 回應欄位

| 欄位 | 型別 | 出現 | 說明 |
| --- | --- | --- | --- |
| `subscriptions` | `array` | 一定有 | 定期購訂單 |
| `subscriptions[].id` | `string` | 可能沒有 | 訂單的內部 id |
| `subscriptions[].status` | `string` | 可能沒有 | `ongoing` 進行中、`retryScheduled` 待重扣、`error` 扣款失敗、`cancelled` 已取消、`done` 已完成 |
| `subscriptions[].items` | `array` | 可能沒有 | 訂購的商品 |
| `subscriptions[].totalAmount` | `number` | 可能沒有 | 每期金額 |
| `subscriptions[].period` | `integer` | 可能沒有 | 已扣期數 |
| `subscriptions[].numberOfPeriods` | `integer` | 可能沒有 | 總期數 |
| `subscriptions[].lastChargedAt` | `string` | 可能沒有 | 最近一次扣款時間（台北時間，帶 `+08:00`） |
| `subscriptions[].user` | `object` | 可能沒有 | 訂購人 `{ name, email }` |
| `subscriptions[].createdAt` | `string` | 可能沒有 | 建立時間 |
| `subscriptions[].cancelledAt` | `string` | 可能沒有 | 取消時間 |
| `subscriptions[].endedAt` | `string` | 可能沒有 | 結束時間（台北時間，帶 `+08:00`） |
| `page` | `string \| null` | 一定有 | 下一頁的分頁標記；沒有下一頁時是 `null` |

## 可能的錯誤

| 錯誤碼 | HTTP | 什麼時候會發生 |
| --- | --- | --- |
| `V0001` | 400 | `status` 值不正確 |
| `A0001` | 401 | token 錯誤 |

完整清單與處理方式見[錯誤碼一覽](error-codes.md)。

## 相關說明

Payment API 建立的定期定額請用[查詢定期定額明細](get-subscription.md)。
