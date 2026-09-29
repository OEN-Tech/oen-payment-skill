---
title: "用 token 扣款"
url: "https://developer.oen.tw/api/token-transactions/"
---

> 來源：https://developer.oen.tw/api/token-transactions/（自動產生，請勿手動修改）

# 用 token 扣款

POST `/token/transactions`

-   正式環境：`https://payment-api.oen.tw/token/transactions`
-   測試環境：`https://payment-api.testing.oen.tw/token/transactions`

用綁卡取得的 token 直接扣款，消費者不需要在場，也不走 3D 驗證。**結果以這支 API 的回應為準，不會送付款通知**。沒有防重複扣款的機制：逾時或收到 5xx 時，請先用[訂單編號查詢](list-order-transactions.md)確認，不要直接重送。

Header 帶 `Authorization: Bearer <token>` 與 `Content-Type: application/json` 。token 的取得方式見[驗證與 token](../developers/authentication.md)。

## 請求

### Body 欄位

| 欄位 | 型別 | 必填 | 說明 |
| --- | --- | --- | --- |
| `merchantId` | `string` | 必填 | 你的網域名稱。例如應援頁是 `https://ming.oen.tw`，就填 `ming`。必須與 token 所屬的網域相同，不同會回 400 `V0001`。 範例：`ming` |
| `amount` | `integer` | 必填 | 金額（新台幣元）。必須等於 `productDetails` 各品項「數量 × 單價」的合計。 限制：1 以上的整數 範例：`1200` |
| `currency` | `string` | 選填 | 幣別，只能是 `TWD`。 可用值：`TWD` 預設：`TWD` |
| `token` | `string` | 必填 | 綁卡通知裡的 `token`。 |
| `orderId` | `string` | 必填 | 你的訂單編號。之後可以用[用訂單編號查詢](list-order-transactions.md)找到這筆訂單的所有交易。 限制：不檢查重複。同一個 `orderId` 可以建立多筆交易 範例：`A20260928001` |
| `productDetails` | `array` | 必填 | 商品明細，用來開立電子發票與顯示在 CRM。**所有品項「數量 × 單價」的合計必須等於 `amount`**，否則回 400 `V0001`（`PRODUCT_AMOUNT_NOT_MATCH`）。 |
| `productDetails[].productionCode` | `string` | 必填 | 商品代碼 |
| `productDetails[].description` | `string` | 必填 | 商品名稱。第一個品項的名稱也會當成交易的商品描述 |
| `productDetails[].quantity` | `integer` | 必填 | 數量 限制：1 以上的整數 |
| `productDetails[].unit` | `string` | 必填 | 單位，例如「個」「份」 |
| `productDetails[].unitPrice` | `integer` | 必填 | 單價（新台幣元） |
| `userId` | `string` | 選填 | 你系統裡的會員編號。 |
| `userName` | `string` | 條件必填 | 消費者姓名。網域有開通電子發票時必填。 |
| `userEmail` | `string (email)` | 條件必填 | 消費者 Email。網域有開通電子發票時必填，發票通知會寄到這裡。 |
| `userPhone` | `string` | 選填 | 消費者手機號碼。網域設定為手機必填時，必須是有效的電話號碼。 |
| `invoiceInfo` | `object` | 選填 | 電子發票資訊。網域有開通電子發票時才有作用；沒帶時開立雲端發票。 |
| `invoiceInfo.invoiceType` | `string` | 必填 | `cloud`：雲端發票；`company`：公司戶（打統編） 可用值：`cloud`、`company` |
| `invoiceInfo.carrierType` | `string` | 雲端發票必填 | 載具類型：`3J0002` 手機條碼、`CQ0001` 自然人憑證、空字串為會員載具 可用值：`3J0002`、`CQ0001`、 |
| `invoiceInfo.carrierId` | `string` | 選填 | 載具號碼。手機條碼格式為 `/` 加 7 碼，會即時向財政部驗證；自然人憑證為 2 個英文字母加 14 碼數字 |
| `invoiceInfo.buyerIdentifier` | `string` | 公司戶必填 | 買受人統一編號，8 碼，會檢查檢查碼 |
| `invoiceInfo.buyerName` | `string` | 選填 | 買受人名稱 |
| `invoiceInfo.email` | `string (email)` | 選填 | 發票通知 Email |
| `note` | `string` | 選填 | 備註。 |
| `expectedPayoutDate` | `string` | 選填 | 期望撥款日期（台北日期），會顯示在 CRM 金流明細。 限制：`yyyy/MM/dd` |

### 請求範例

範例一律打測試環境。把 `OEN_API_TOKEN` 設成測試環境 CRM 產生的 token。

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
  "userName": "王小明",
  "userEmail": "ming@example.com",
  "productDetails": [
    {
      "productionCode": "SKU-001",
      "description": "手沖咖啡豆 200g",
      "quantity": 2,
      "unit": "包",
      "unitPrice": 600
    }
  ]
}'
```

```js
const res = await fetch("https://payment-api.testing.oen.tw/token/transactions", {
  method: "POST",
  headers: {
    Authorization: `Bearer ${process.env.OEN_API_TOKEN}`,
    "Content-Type": "application/json",
  },
  body: JSON.stringify({
    "merchantId": "ming",
    "amount": 1200,
    "token": "2HhnhWm8Qe0sPz4LbXv9KdYt1Ra",
    "orderId": "A20260928003",
    "userName": "王小明",
    "userEmail": "ming@example.com",
    "productDetails": [
      {
        "productionCode": "SKU-001",
        "description": "手沖咖啡豆 200g",
        "quantity": 2,
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
$ch = curl_init('https://payment-api.testing.oen.tw/token/transactions');
curl_setopt_array($ch, [
    CURLOPT_CUSTOMREQUEST => 'POST',
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_HTTPHEADER => [
        'Authorization: Bearer ' . getenv('OEN_API_TOKEN'),
        'Content-Type: application/json',
    ],
    CURLOPT_POSTFIELDS => json_encode([
        'merchantId' => 'ming',
        'amount' => 1200,
        'token' => '2HhnhWm8Qe0sPz4LbXv9KdYt1Ra',
        'orderId' => 'A20260928003',
        'userName' => '王小明',
        'userEmail' => 'ming@example.com',
        'productDetails' => [
            [
                'productionCode' => 'SKU-001',
                'description' => '手沖咖啡豆 200g',
                'quantity' => 2,
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
    "https://payment-api.testing.oen.tw/token/transactions",
    headers={"Authorization": f"Bearer {os.environ['OEN_API_TOKEN']}"},
    json={
        "merchantId": "ming",
        "amount": 1200,
        "token": "2HhnhWm8Qe0sPz4LbXv9KdYt1Ra",
        "orderId": "A20260928003",
        "userName": "王小明",
        "userEmail": "ming@example.com",
        "productDetails": [
            {
                "productionCode": "SKU-001",
                "description": "手沖咖啡豆 200g",
                "quantity": 2,
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
| `200` | 扣款成功 |
| `400` | 扣款失敗（`T0001`～`T0005`）或參數錯誤。失敗的交易仍會建立，可以用訂單編號查到 |
| `401` | token 錯誤 |
| `409` | 付款結果不明（`C026`）。**不要重試**，先查詢交易狀態 |

### 回應欄位

| 欄位 | 型別 | 出現 | 說明 |
| --- | --- | --- | --- |
| `id` | `string` | 一定有 | 交易編號（`P` 開頭），退款用這個 |
| `authCode` | `string` | 可能沒有 | 授權碼 |

### 回應範例

```json
{
  "code": "S0000",
  "data": {
    "id": "P20260928IJ90KL12",
    "authCode": "831000"
  },
  "message": ""
}
```

## 可能的錯誤

| 錯誤碼 | HTTP | 什麼時候會發生 |
| --- | --- | --- |
| `T0001` | 400 | 交易失敗（一般原因） |
| `T0002` | 400 | 安全碼錯誤 |
| `T0003` | 400 | 卡片過期 |
| `T0004` | 400 | 額度不足 |
| `T0005` | 400 | 發卡銀行拒絕授權 |
| `V0001` | 400 | 欄位不符規則、品項合計不等於金額 |
| `V0002` | 400 | 網域的金流服務尚未開通 |
| `V0003` | 400 | 單筆 200,000 元以上，但網域沒有開通高額交易 |
| `C026` | 409 | 付款結果不明，回應帶 `"retryable": false` |
| `A0001` | 401 | token 錯誤 |

完整清單與處理方式見[錯誤碼一覽](error-codes.md)。

## 相關說明

什麼時候適合用、如何避免重複扣款，見[存卡與後續扣款](../developers/saved-cards.md)。
