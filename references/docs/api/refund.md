---
title: "退款"
url: "https://developer.oen.tw/api/refund/"
---

> 來源：https://developer.oen.tw/api/refund/（自動產生，請勿手動修改）

# 退款

POST `/refunds/:transactionHid`

-   正式環境：`https://payment-api.oen.tw/refunds/:transactionHid`
-   測試環境：`https://payment-api.testing.oen.tw/refunds/:transactionHid`

為一筆交易退款。**每筆交易只能用 API 成功退款一次**，部分退款後剩下的金額不能再退，請一次決定好金額。信用卡、Apple Pay、LINE Pay 即時退款；已付款的超商代碼與 ATM 要帶退款帳戶，由應援匯款；尚未繳費的超商代碼會直接取消代碼。

Header 帶 `Authorization: Bearer <token>` 與 `Content-Type: application/json` 。token 的取得方式見[驗證與 token](../developers/authentication.md)。

## 請求

### 路徑參數

| 欄位 | 型別 | 必填 | 說明 |
| --- | --- | --- | --- |
| `transactionHid` | `string` | 必填 | `P` 開頭的交易編號（17 字元）。不接受 27 字元的內部 id。 |

### Body 欄位

| 欄位 | 型別 | 必填 | 說明 |
| --- | --- | --- | --- |
| `merchantId` | `string` | 必填 | 你的網域名稱。例如應援頁是 `https://ming.oen.tw`，就填 `ming`。必須與 token 所屬的網域相同，不同會回 400 `V0001`。 範例：`ming` |
| `amount` | `integer` | 選填 | 退款金額。不帶就是全額退款。 限制：1 以上，不能大於原交易金額 |
| `reason` | `string` | 選填 | 退款原因。 |
| `productDetails` | `array` | 條件必填 | 原交易有開立電子發票時必填，用來開立折讓。品項合計必須等於退款金額。欄位同建立交易時的 `productDetails`。 |
| `remitInfo` | `object` | 條件必填 | 退款匯款帳戶。**已付款的超商代碼或 ATM 交易**必填；信用卡類與尚未繳費的超商代碼不用帶。 |
| `remitInfo.bankCode` | `string` | 必填 | 銀行代碼 |
| `remitInfo.bankName` | `string` | 必填 | 銀行名稱 |
| `remitInfo.branchCode` | `string` | 必填 | 分行代碼 |
| `remitInfo.branchName` | `string` | 必填 | 分行名稱 |
| `remitInfo.account` | `string` | 必填 | 帳號 限制：8 到 14 字元 |
| `remitInfo.accountName` | `string` | 必填 | 戶名 |

### 請求範例

範例一律打測試環境。把 `OEN_API_TOKEN` 設成測試環境 CRM 產生的 token。

終端機視窗

```bash
curl -X POST "https://payment-api.testing.oen.tw/refunds/P20260928AB12CD34" \
  -H "Authorization: Bearer $OEN_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
  "merchantId": "ming",
  "amount": 600,
  "reason": "消費者取消一包",
  "productDetails": [
    {
      "productionCode": "SKU-001",
      "description": "手沖咖啡豆 200g",
      "quantity": 1,
      "unit": "包",
      "unitPrice": 600
    }
  ]
}'
```

```js
const res = await fetch("https://payment-api.testing.oen.tw/refunds/P20260928AB12CD34", {
  method: "POST",
  headers: {
    Authorization: `Bearer ${process.env.OEN_API_TOKEN}`,
    "Content-Type": "application/json",
  },
  body: JSON.stringify({
    "merchantId": "ming",
    "amount": 600,
    "reason": "消費者取消一包",
    "productDetails": [
      {
        "productionCode": "SKU-001",
        "description": "手沖咖啡豆 200g",
        "quantity": 1,
        "unit": "包",
        "unitPrice": 600
      }
    ]
  }),
});

const result = await res.json();
if (result.code !== "S0000") {
  throw new Error(`${result.code} ${result.message}`);
}
```

```php
<?php
$ch = curl_init('https://payment-api.testing.oen.tw/refunds/P20260928AB12CD34');
curl_setopt_array($ch, [
    CURLOPT_CUSTOMREQUEST => 'POST',
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_HTTPHEADER => [
        'Authorization: Bearer ' . getenv('OEN_API_TOKEN'),
        'Content-Type: application/json',
    ],
    CURLOPT_POSTFIELDS => json_encode([
        'merchantId' => 'ming',
        'amount' => 600,
        'reason' => '消費者取消一包',
        'productDetails' => [
            [
                'productionCode' => 'SKU-001',
                'description' => '手沖咖啡豆 200g',
                'quantity' => 1,
                'unit' => '包',
                'unitPrice' => 600,
            ],
        ],
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
    "https://payment-api.testing.oen.tw/refunds/P20260928AB12CD34",
    headers={"Authorization": f"Bearer {os.environ['OEN_API_TOKEN']}"},
    json={
        "merchantId": "ming",
        "amount": 600,
        "reason": "消費者取消一包",
        "productDetails": [
            {
                "productionCode": "SKU-001",
                "description": "手沖咖啡豆 200g",
                "quantity": 1,
                "unit": "包",
                "unitPrice": 600,
            },
        ],
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
| `200` | 退款已受理。回傳更新後的 [Transaction 物件](objects/transaction.md)，另加 `success: true` |
| `400` | 參數錯誤、交易狀態不能退款，或收單機構退款失敗 |
| `401` | token 錯誤 |
| `500` | 系統錯誤，或網域待撥款金額不足（見下方錯誤表） |

### 回應範例

```json
{
  "code": "S0000",
  "data": {
    "success": true,
    "id": "P20260928AB12CD34",
    "transactionId": "2HhndgEquCbDzC5OyVxWSGZmd2l",
    "action": "onetime",
    "amount": 1200,
    "paymentMethod": "card",
    "status": "refunded",
    "orderId": "A20260928001",
    "createdAt": "2026-09-28T02:40:25.502Z",
    "paidAt": "2026-09-28T02:41:03.118Z",
    "refundAmount": 600,
    "refundedAt": "2026-09-28T03:00:00.000Z",
    "authCode": "831000"
  },
  "message": ""
}
```

## 可能的錯誤

| 錯誤碼 | HTTP | 什麼時候會發生 |
| --- | --- | --- |
| `V0001` | 400 | 找不到交易或不屬於你的網域；金額錯誤（`INVALID_REFUND_AMOUNT`）或超過原金額（`REFUND_AMOUNT_EXCEED_CHARGE_AMOUNT`）；缺少折讓品項（`PRODUCT_DETAILS_REQUIRED`、`PRODUCT_AMOUNT_NOT_MATCH`）；缺少退款帳戶（`REMITTANCE_INFO_REQUIRED`） |
| `V0002` | 400 | 交易狀態不能退款，例如尚未付款、已經退過款 |
| `R0001` | 400 | 收單機構退款失敗。先查詢交易狀態；之後重試都回 `V0002` 時，請聯絡應援 |
| `F0001` | 500 | 訊息為 `Current charged amount too low`：你的網域尚未撥款的已收款淨額低於 200 元，暫時無法退款，請聯絡應援。其他訊息為系統錯誤 |
| `A0001` | 401 | token 錯誤 |

完整清單與處理方式見[錯誤碼一覽](error-codes.md)。

## 相關說明

各付款方式的退款規則見[退款](../developers/refunds.md)。
