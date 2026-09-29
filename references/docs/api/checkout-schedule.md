---
title: "建立預約定期定額"
url: "https://developers.oentech.ai/api/checkout-schedule/"
---

> 來源：https://developers.oentech.ai/api/checkout-schedule/（自動產生，請勿手動修改）

# 建立預約定期定額

POST `/checkout-schedule`

-   正式環境：`https://payment-api.oen.tw/checkout-schedule`
-   測試環境：`https://payment-api.testing.oen.tw/checkout-schedule`

建立可以指定首期扣款日與扣款間隔的定期定額，回傳 `id` 與定期定額編號 `subscriptionHid`。把消費者導到 `https://{merchantId}.oen.tw/checkout/schedule/{id}`。首期日是今天時，消費者付款當下扣第一期；是未來日期時，消費者只綁卡，到期由應援扣款。結帳頁 5 分鐘內有效。

Header 帶 `Authorization: Bearer <token>` 與 `Content-Type: application/json` 。token 的取得方式見[驗證與 token](../developers/authentication.md)。

## 請求

### Body 欄位

| 欄位 | 型別 | 必填 | 說明 |
| --- | --- | --- | --- |
| `merchantId` | `string` | 必填 | 你的網域名稱。例如應援頁是 `https://ming.oen.tw`，就填 `ming`。必須與 token 所屬的網域相同，不同會回 400 `V0001`。 範例：`ming` |
| `amount` | `integer` | 必填 | 每期金額（新台幣元）。必須等於 `productDetails` 的合計。 限制：1 以上的整數 範例：`1200` |
| `currency` | `string` | 選填 | 幣別。目前只支援新台幣。 可用值：`TWD` 預設：`TWD` |
| `numberOfPeriods` | `integer` | 選填 | 總期數。不帶就是不限期，直到取消。 限制：2 以上 |
| `paymentInterval` | `integer` | 選填 | 每幾個月扣款一次。 限制：1 到 12 預設：`1` |
| `startDate` | `string \| null` | 選填 | 首期扣款日（台北日期）。不帶就是今天。 限制：`yyyy/MM/dd`；今天到 12 個月內 範例：`2026/10/15` |
| `orderId` | `string` | 必填 | 你的訂單編號。之後可以用[用訂單編號查詢](list-order-transactions.md)找到這筆訂單的所有交易。 限制：不檢查重複。同一個 `orderId` 可以建立多筆交易 範例：`A20260928001` |
| `successUrl` | `string (uri) \| null` | 必填 | 付款成功後把消費者導回的網址。**導回時不帶任何參數**，請在網址裡放自己的訂單編號，例如 `https://shop.example.com/thanks?order=A001`。導回不代表付款成功，請以付款通知或查詢結果為準。 限制：要寫完整網址（含 `https://`）；可以是 `null`，但欄位一定要有 |
| `failureUrl` | `string (uri) \| null` | 必填 | 付款失敗或逾時後導回的網址，會加上 `payment_error` 參數，可能的值見[錯誤碼一覽](error-codes.md#結帳頁導回的-payment_error)。 限制：同 `successUrl`。建議不要自帶 `?` 參數與 `#` 片段 |
| `productDetails` | `array` | 必填 | 商品明細，用來開立電子發票與顯示在 CRM。**所有品項「數量 × 單價」的合計必須等於 `amount`**，否則回 400 `V0001`（`PRODUCT_AMOUNT_NOT_MATCH`）。 |
| `productDetails[].productionCode` | `string` | 必填 | 商品代碼 |
| `productDetails[].description` | `string` | 必填 | 商品名稱。第一個品項的名稱也會當成交易的商品描述 |
| `productDetails[].quantity` | `integer` | 必填 | 數量 限制：1 以上的整數 |
| `productDetails[].unit` | `string` | 必填 | 單位，例如「個」「份」 |
| `productDetails[].unitPrice` | `integer` | 必填 | 單價（新台幣元） |
| `userId` | `string` | 選填 | 你系統裡的會員編號。 |
| `userName` | `string` | 條件必填 | 消費者姓名。網域有開通電子發票時必填。 |
| `userEmail` | `string (email)` | 條件必填 | 消費者 Email。網域有開通電子發票時必填，發票通知會寄到這裡。 |
| `invoiceInfo` | `object` | 選填 | 電子發票資訊。網域有開通電子發票時才有作用；沒帶時開立雲端發票。 |
| `invoiceInfo.invoiceType` | `string` | 必填 | `cloud`：雲端發票；`company`：公司戶（打統編） 可用值：`cloud`、`company` |
| `invoiceInfo.carrierType` | `string` | 雲端發票必填 | 載具類型：`3J0002` 手機條碼、`CQ0001` 自然人憑證、空字串為會員載具 可用值：`3J0002`、`CQ0001`、 |
| `invoiceInfo.carrierId` | `string` | 選填 | 載具號碼。手機條碼格式為 `/` 加 7 碼，會即時向財政部驗證；自然人憑證為 2 個英文字母加 14 碼數字 |
| `invoiceInfo.buyerIdentifier` | `string` | 公司戶必填 | 買受人統一編號，8 碼，會檢查檢查碼 |
| `invoiceInfo.buyerName` | `string` | 選填 | 買受人名稱 |
| `invoiceInfo.email` | `string (email)` | 選填 | 發票通知 Email |
| `customId` | `string` | 選填 | 你自訂的資料，會原樣出現在付款通知與查詢結果中。 |
| `note` | `string` | 選填 | 備註。 |
| `use3d` | `boolean` | 選填 | 是否走 3D 驗證。網域被設定為一律 3D 時會強制開啟。 預設：`false` |

### 請求範例

範例一律打測試環境。把 `OEN_API_TOKEN` 設成測試環境 CRM 產生的 token。

終端機視窗

```bash
curl -X POST "https://payment-api.testing.oen.tw/checkout-schedule" \
  -H "Authorization: Bearer $OEN_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
  "merchantId": "ming",
  "amount": 1500,
  "numberOfPeriods": 4,
  "paymentInterval": 3,
  "startDate": "2026/10/15",
  "orderId": "SUB20260928002",
  "successUrl": "https://shop.example.com/subscribe/success?order=SUB20260928002",
  "failureUrl": "https://shop.example.com/subscribe/failure/SUB20260928002",
  "userName": "王小明",
  "userEmail": "ming@example.com",
  "productDetails": [
    {
      "productionCode": "BOX-Q",
      "description": "季訂閱禮盒",
      "quantity": 1,
      "unit": "盒",
      "unitPrice": 1500
    }
  ]
}'
```

```js
const res = await fetch("https://payment-api.testing.oen.tw/checkout-schedule", {
  method: "POST",
  headers: {
    Authorization: `Bearer ${process.env.OEN_API_TOKEN}`,
    "Content-Type": "application/json",
  },
  body: JSON.stringify({
    "merchantId": "ming",
    "amount": 1500,
    "numberOfPeriods": 4,
    "paymentInterval": 3,
    "startDate": "2026/10/15",
    "orderId": "SUB20260928002",
    "successUrl": "https://shop.example.com/subscribe/success?order=SUB20260928002",
    "failureUrl": "https://shop.example.com/subscribe/failure/SUB20260928002",
    "userName": "王小明",
    "userEmail": "ming@example.com",
    "productDetails": [
      {
        "productionCode": "BOX-Q",
        "description": "季訂閱禮盒",
        "quantity": 1,
        "unit": "盒",
        "unitPrice": 1500
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
$ch = curl_init('https://payment-api.testing.oen.tw/checkout-schedule');
curl_setopt_array($ch, [
    CURLOPT_CUSTOMREQUEST => 'POST',
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_HTTPHEADER => [
        'Authorization: Bearer ' . getenv('OEN_API_TOKEN'),
        'Content-Type: application/json',
    ],
    CURLOPT_POSTFIELDS => json_encode([
        'merchantId' => 'ming',
        'amount' => 1500,
        'numberOfPeriods' => 4,
        'paymentInterval' => 3,
        'startDate' => '2026/10/15',
        'orderId' => 'SUB20260928002',
        'successUrl' => 'https://shop.example.com/subscribe/success?order=SUB20260928002',
        'failureUrl' => 'https://shop.example.com/subscribe/failure/SUB20260928002',
        'userName' => '王小明',
        'userEmail' => 'ming@example.com',
        'productDetails' => [
            [
                'productionCode' => 'BOX-Q',
                'description' => '季訂閱禮盒',
                'quantity' => 1,
                'unit' => '盒',
                'unitPrice' => 1500,
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
    "https://payment-api.testing.oen.tw/checkout-schedule",
    headers={"Authorization": f"Bearer {os.environ['OEN_API_TOKEN']}"},
    json={
        "merchantId": "ming",
        "amount": 1500,
        "numberOfPeriods": 4,
        "paymentInterval": 3,
        "startDate": "2026/10/15",
        "orderId": "SUB20260928002",
        "successUrl": "https://shop.example.com/subscribe/success?order=SUB20260928002",
        "failureUrl": "https://shop.example.com/subscribe/failure/SUB20260928002",
        "userName": "王小明",
        "userEmail": "ming@example.com",
        "productDetails": [
            {
                "productionCode": "BOX-Q",
                "description": "季訂閱禮盒",
                "quantity": 1,
                "unit": "盒",
                "unitPrice": 1500,
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
| `400` | 參數錯誤 |
| `401` | token 錯誤 |

### 回應欄位

| 欄位 | 型別 | 出現 | 說明 |
| --- | --- | --- | --- |
| `id` | `string` | 一定有 | 定期定額的內部 id，組結帳頁網址用 |
| `subscriptionHid` | `string` | 一定有 | 定期定額編號，`S` 開頭共 17 字元。查詢與取消定期定額都用這個 |

### 回應範例

```json
{
  "code": "S0000",
  "data": {
    "id": "2HhnfZ1kqRmA7cX0TQwq8vBn3Ls",
    "subscriptionHid": "S20260928EF56GH78"
  },
  "message": ""
}
```

## 可能的錯誤

| 錯誤碼 | HTTP | 什麼時候會發生 |
| --- | --- | --- |
| `V0001` | 400 | 欄位不符規則；首期日早於今天（`START_DATE_MUST_GREATER_THAN_TODAY`）或超過 12 個月（`START_DATE_MUST_LESS_THAN_12_MONTHS`）；品項合計不等於金額 |
| `K0001` | 400 | 個人身分商家的交易金額超過風控門檻 |
| `A0001` | 401 | token 錯誤 |

完整清單與處理方式見[錯誤碼一覽](error-codes.md)。

## 相關說明

跟「建立定期定額」的差別見[定期定額](../developers/subscriptions.md)。
