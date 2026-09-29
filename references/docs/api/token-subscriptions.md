---
title: "用 token 建立定期定額"
url: "https://developer.oen.tw/api/token-subscriptions/"
---

> 來源：https://developer.oen.tw/api/token-subscriptions/（自動產生，請勿手動修改）

# 用 token 建立定期定額

POST `/token/subscriptions`

-   正式環境：`https://payment-api.oen.tw/token/subscriptions`
-   測試環境：`https://payment-api.testing.oen.tw/token/subscriptions`

用綁卡取得的 token 建立定期定額。不帶 `startDate` 時當下扣第一期，結果以回應為準（第一期不送付款通知，之後每期會送）；帶未來日期時只建立排程，到期才扣款。

Header 帶 `Authorization: Bearer <token>` 與 `Content-Type: application/json` 。token 的取得方式見[驗證與 token](../developers/authentication.md)。

## 請求

### Body 欄位

| 欄位 | 型別 | 必填 | 說明 |
| --- | --- | --- | --- |
| `merchantId` | `string` | 必填 | 你的網域名稱。例如應援頁是 `https://ming.oen.tw`，就填 `ming`。必須與 token 所屬的網域相同，不同會回 400 `V0001`。 範例：`ming` |
| `amount` | `integer` | 必填 | 每期金額（新台幣元）。必須等於 `productDetails` 的合計。 限制：1 以上的整數 範例：`1200` |
| `currency` | `string` | 選填 | 幣別，只能是 `TWD`。 可用值：`TWD` 預設：`TWD` |
| `token` | `string` | 必填 | 綁卡通知裡的 `token`。 |
| `numberOfPeriods` | `integer` | 選填 | 總期數。不帶就是不限期，直到取消。 限制：2 以上 |
| `paymentInterval` | `integer` | 選填 | 每幾個月扣款一次。 限制：1 到 12 預設：`1` |
| `startDate` | `string` | 選填 | 首期扣款日（台北日期）。不帶就立即扣第一期。 限制：`yyyy/MM/dd`；**必須晚於今天**，最晚 12 個月內 |
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

### 請求範例

範例一律打測試環境。把 `OEN_API_TOKEN` 設成測試環境 CRM 產生的 token。

終端機視窗

```bash
curl -X POST "https://payment-api.testing.oen.tw/token/subscriptions" \
  -H "Authorization: Bearer $OEN_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
  "merchantId": "ming",
  "amount": 299,
  "token": "2HhnhWm8Qe0sPz4LbXv9KdYt1Ra",
  "numberOfPeriods": 12,
  "paymentInterval": 1,
  "orderId": "SUB20260928003",
  "userName": "王小明",
  "userEmail": "ming@example.com",
  "productDetails": [
    {
      "productionCode": "PLAN-M",
      "description": "月費會員",
      "quantity": 1,
      "unit": "月",
      "unitPrice": 299
    }
  ]
}'
```

```js
const res = await fetch("https://payment-api.testing.oen.tw/token/subscriptions", {
  method: "POST",
  headers: {
    Authorization: `Bearer ${process.env.OEN_API_TOKEN}`,
    "Content-Type": "application/json",
  },
  body: JSON.stringify({
    "merchantId": "ming",
    "amount": 299,
    "token": "2HhnhWm8Qe0sPz4LbXv9KdYt1Ra",
    "numberOfPeriods": 12,
    "paymentInterval": 1,
    "orderId": "SUB20260928003",
    "userName": "王小明",
    "userEmail": "ming@example.com",
    "productDetails": [
      {
        "productionCode": "PLAN-M",
        "description": "月費會員",
        "quantity": 1,
        "unit": "月",
        "unitPrice": 299
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
$ch = curl_init('https://payment-api.testing.oen.tw/token/subscriptions');
curl_setopt_array($ch, [
    CURLOPT_CUSTOMREQUEST => 'POST',
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_HTTPHEADER => [
        'Authorization: Bearer ' . getenv('OEN_API_TOKEN'),
        'Content-Type: application/json',
    ],
    CURLOPT_POSTFIELDS => json_encode([
        'merchantId' => 'ming',
        'amount' => 299,
        'token' => '2HhnhWm8Qe0sPz4LbXv9KdYt1Ra',
        'numberOfPeriods' => 12,
        'paymentInterval' => 1,
        'orderId' => 'SUB20260928003',
        'userName' => '王小明',
        'userEmail' => 'ming@example.com',
        'productDetails' => [
            [
                'productionCode' => 'PLAN-M',
                'description' => '月費會員',
                'quantity' => 1,
                'unit' => '月',
                'unitPrice' => 299,
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
    "https://payment-api.testing.oen.tw/token/subscriptions",
    headers={"Authorization": f"Bearer {os.environ['OEN_API_TOKEN']}"},
    json={
        "merchantId": "ming",
        "amount": 299,
        "token": "2HhnhWm8Qe0sPz4LbXv9KdYt1Ra",
        "numberOfPeriods": 12,
        "paymentInterval": 1,
        "orderId": "SUB20260928003",
        "userName": "王小明",
        "userEmail": "ming@example.com",
        "productDetails": [
            {
                "productionCode": "PLAN-M",
                "description": "月費會員",
                "quantity": 1,
                "unit": "月",
                "unitPrice": 299,
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
| `200` | 建立成功 |
| `400` | 第一期扣款失敗（`T0001`～`T0005`）或參數錯誤 |
| `401` | token 錯誤 |
| `409` | 第一期付款結果不明（`C026`），不要重試 |

### 回應欄位

| 欄位 | 型別 | 出現 | 說明 |
| --- | --- | --- | --- |
| `subscriptionId` | `string` | 一定有 | 定期定額編號（`S` 開頭） |
| `transactionId` | `string` | 可能沒有 | 第一期交易編號（`P` 開頭）。帶未來 `startDate` 時沒有 |
| `authCode` | `string` | 可能沒有 | 第一期的授權碼。帶未來 `startDate` 時沒有 |

### 回應範例

```json
{
  "code": "S0000",
  "data": {
    "subscriptionId": "S20260928MN34OP56",
    "transactionId": "P20260928QR78ST90",
    "authCode": "831000"
  },
  "message": ""
}
```

## 可能的錯誤

| 錯誤碼 | HTTP | 什麼時候會發生 |
| --- | --- | --- |
| `T0001` | 400 | 第一期扣款失敗。定期定額不會成立 |
| `V0001` | 400 | 欄位不符規則；首期日不存在（`INVALID_START_DATE`）、不晚於今天（`START_DATE_MUST_GREATER_THAN_TODAY`）或超過 12 個月 |
| `V0002` | 400 | 網域的金流服務尚未開通 |
| `C026` | 409 | 第一期付款結果不明 |
| `A0001` | 401 | token 錯誤 |

完整清單與處理方式見[錯誤碼一覽](error-codes.md)。

## 相關說明

見[存卡與後續扣款](../developers/saved-cards.md)與[定期定額](../developers/subscriptions.md)。
