---
title: "建立綁卡頁"
url: "https://developer.oen.tw/api/checkout-token/"
---

> 來源：https://developer.oen.tw/api/checkout-token/（自動產生，請勿手動修改）

# 建立綁卡頁

POST `/checkout-token`

-   正式環境：`https://payment-api.oen.tw/checkout-token`
-   測試環境：`https://payment-api.testing.oen.tw/checkout-token`

建立綁卡頁，回傳 `id`。把消費者導到 `https://{merchantId}.oen.tw/checkout/subscription/create/{id}` 完成 3D 驗證並綁卡。**綁卡頁 10 分鐘內有效。token 只會透過付款通知（`purpose` 為 `token`）送給你**，導回網址不帶 token，也沒有查詢 API。

Header 帶 `Authorization: Bearer <token>` 與 `Content-Type: application/json` 。token 的取得方式見[驗證與 token](../developers/authentication.md)。

## 請求

### Body 欄位

| 欄位 | 型別 | 必填 | 說明 |
| --- | --- | --- | --- |
| `merchantId` | `string` | 必填 | 你的網域名稱。例如應援頁是 `https://ming.oen.tw`，就填 `ming`。必須與 token 所屬的網域相同，不同會回 400 `V0001`。 範例：`ming` |
| `successUrl` | `string (uri) \| null` | 必填 | 綁卡成功後導回的網址。**不帶 token**。 限制：要寫完整網址（含 `https://`）；可以是 `null`，但欄位一定要有 |
| `failureUrl` | `string (uri) \| null` | 必填 | 綁卡失敗或逾時後導回的網址，會加上 `payment_error`。 限制：同 `successUrl`。建議不要自帶 `?` 參數與 `#` 片段 |
| `customId` | `string` | 選填 | 你自訂的資料，會出現在 token 通知裡，方便你對應是哪一位會員。 |
| `note` | `string` | 選填 | 備註。 |
| `payerEmail` | `string (email)` | 選填 | 持卡人 Email。沒帶時消費者要在綁卡頁自行填寫。 |

### 請求範例

範例一律打測試環境。把 `OEN_API_TOKEN` 設成測試環境 CRM 產生的 token。

終端機視窗

```bash
curl -X POST "https://payment-api.testing.oen.tw/checkout-token" \
  -H "Authorization: Bearer $OEN_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
  "merchantId": "ming",
  "successUrl": "https://shop.example.com/cards/added?member=M001",
  "failureUrl": "https://shop.example.com/cards/failed/M001",
  "customId": "M001",
  "payerEmail": "ming@example.com"
}'
```

```js
const res = await fetch("https://payment-api.testing.oen.tw/checkout-token", {
  method: "POST",
  headers: {
    Authorization: `Bearer ${process.env.OEN_API_TOKEN}`,
    "Content-Type": "application/json",
  },
  body: JSON.stringify({
    "merchantId": "ming",
    "successUrl": "https://shop.example.com/cards/added?member=M001",
    "failureUrl": "https://shop.example.com/cards/failed/M001",
    "customId": "M001",
    "payerEmail": "ming@example.com"
  }),
});

const result = await res.json();
if (result.code !== "S0000") {
  throw new Error(`${result.code} ${result.message}`);
}
```

```php
<?php
$ch = curl_init('https://payment-api.testing.oen.tw/checkout-token');
curl_setopt_array($ch, [
    CURLOPT_CUSTOMREQUEST => 'POST',
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_HTTPHEADER => [
        'Authorization: Bearer ' . getenv('OEN_API_TOKEN'),
        'Content-Type: application/json',
    ],
    CURLOPT_POSTFIELDS => json_encode([
        'merchantId' => 'ming',
        'successUrl' => 'https://shop.example.com/cards/added?member=M001',
        'failureUrl' => 'https://shop.example.com/cards/failed/M001',
        'customId' => 'M001',
        'payerEmail' => 'ming@example.com',
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
    "POST",
    "https://payment-api.testing.oen.tw/checkout-token",
    headers={"Authorization": f"Bearer {os.environ['OEN_API_TOKEN']}"},
    json={
        "merchantId": "ming",
        "successUrl": "https://shop.example.com/cards/added?member=M001",
        "failureUrl": "https://shop.example.com/cards/failed/M001",
        "customId": "M001",
        "payerEmail": "ming@example.com",
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
| `200` | 建立成功 |
| `400` | 參數錯誤或金流未開通 |
| `401` | token 錯誤 |

### 回應欄位

| 欄位 | 型別 | 出現 | 說明 |
| --- | --- | --- | --- |
| `id` | `string` | 一定有 | 綁卡請求的 id。組綁卡頁網址用，也會出現在 token 通知的 `id` |

### 回應範例

```json
{
  "code": "S0000",
  "data": {
    "id": "2HhngP9sVb3mK1xYdQe7Wc0RtUi"
  },
  "message": ""
}
```

## 可能的錯誤

| 錯誤碼 | HTTP | 什麼時候會發生 |
| --- | --- | --- |
| `V0001` | 400 | 欄位不符規則 |
| `V0002` | 400 | 網域的金流服務尚未開通 |
| `A0001` | 401 | token 錯誤 |

完整清單與處理方式見[錯誤碼一覽](error-codes.md)。

## 相關說明

完整流程見[存卡與後續扣款](../developers/saved-cards.md)。
