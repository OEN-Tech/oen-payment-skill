# Oen Payment REST API Complete Reference

## Endpoints

- Production: `https://payment-api.oen.tw`
- Testing: `https://payment-api.testing.oen.tw`

## Headers

```
Content-Type: application/json
Authorization: Bearer {authToken}
```

## HTTP Response Status Codes

- 200 - Success
- 401 - Unauthorized
- 400 - Bad request
- 500 - Server error

## Response Structure

```json
{
  "code": "",
  "message": "",
  "data": {}
}
```

## Important Notes

- Replace `token` with the one obtained from Oen CRM dashboard
- Replace `merchantId` with your domain name (e.g., if your page URL is `https://ming.oen.tw`, use `ming`)
- Use testing environment tokens for testing, production tokens for production
- To test success: amount > 100; to test failure: amount < 100
- Non-required fields without values are omitted from responses (no key present)
- All dates are ISO 8601 format (UTC+0)
- List endpoints return 50 items per page; use `page` token from previous response for next page

## Test Card Numbers

| Card Number | Purpose |
|-------------|---------|
| 4242 4242 4242 4242 | Successful payment |
| 4000 0000 0000 2503 | Triggers 3D Secure verification |
| 5200 0000 0000 2151 | Triggers 3D Secure verification |
| 4012 8888 1888 8333 | Triggers failure scenario |

## Response Codes

| Code | Description |
|------|-------------|
| S0000 | Success |
| A0001 | Unauthorized |
| V0001 | Bad request |
| V0002 | Invalid transaction status |
| T0001 | Transaction failed |
| T0002 | CVV error |
| T0003 | Card expired |
| T0004 | Insufficient credit |
| T0005 | Authorization denied |
| F0001 | System error |

---

## Redirect-Based Checkout Flows

### Webhook Setup

Set webhook endpoint in Oen CRM. Transaction results are sent asynchronously.

If an error occurs during checkout, the failure URL receives the error code as a query parameter:
```
https://www.yourdomain.com.tw/fail?payment_error=V0001
```

### Webhook Payload

Webhook retries 3 times on failure (intervals: 2s, 4s, 6s).

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| merchantId | string | Yes | Merchant ID |
| success | boolean | Yes | Whether transaction succeeded |
| id (transactionId) | string | Yes | Transaction ID (e.g., 2gZlnLRUiOZlnzEFvMrcURtTlHg) |
| purpose | string | Yes | `charge` (payment) or `token` (card tokenization) |
| status | string | When purpose=charge | initiated / charging / failed / charged / claimed |
| transactionHid | string | When purpose=charge | Human-readable ID (e.g., P20240517VRTJYBAJ) |
| action | string | When purpose=charge | onetime / subscription |
| amount | number | When purpose=charge | Transaction amount |
| currency | string | When purpose=charge | Currency code |
| orderId | string | If provided | Your order ID |
| userId | string | If provided | Consumer ID |
| customId | string | If provided | Your custom data |
| paymentMethod | string | When purpose=charge | card / atm / cvs |
| paymentInfo | string/object | Optional | Card: last 4 digits; CVS: `{ cvsName, code, expiredAt }`; LINE Pay: transaction ID |
| authCode | string | card only | Authorization code |
| productDetails | array | If invoicing | Product details array |
| token | string | token purpose | Card token |
| subscriptionId | string | subscription | Subscription ID |
| period | number | subscription | Current period |
| numberOfPeriods | number | subscription | Total periods (0 = unlimited) |
| nextChargeAt | string | subscription | Next charge date |
| message | string | On error | Error message |

---

## POST /checkout — Create Single Payment Page

### Request

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| merchantId | string | Yes | Merchant domain name |
| amount | number | Yes | Transaction amount |
| currency | string | Yes | Currency (TWD) |
| orderId | string | Yes | Your order ID |
| successUrl | string | Yes | Redirect URL on success |
| failureUrl | string | Yes | Redirect URL on failure |
| productDetails | array | For invoicing | Product items (see below) |
| userName | string | For invoicing | Consumer name |
| userEmail | string | For invoicing | Consumer email |
| allowedPaymentMethods | array | No | Additional methods: `["cvs"]`, `["linePay"]` |
| use3d | boolean | No | Enable 3D Secure (default: false) |
| customId | string | No | Custom data returned in webhook |
| userId | string | No | Consumer ID |
| note | string | No | Memo |

### productDetails Item

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| productionCode | string | Yes | Product code |
| description | string | Yes | Product description |
| quantity | number | Yes | Quantity |
| unit | string | Yes | Unit |
| unitPrice | number | Yes | Unit price |

### Redirect After Response

- Production: `https://{merchantId}.oen.tw/checkout/{data.id}`
- Testing: `https://{merchantId}.testing.oen.tw/checkout/{data.id}`

### Example Request

```json
{
  "merchantId": "oentech",
  "amount": 1000,
  "currency": "TWD",
  "orderId": "ORDER00001",
  "successUrl": "https://your-site.com/success",
  "failureUrl": "https://your-site.com/fail"
}
```

### Example Response

```json
{
  "code": "S0000",
  "data": {
    "id": "2HhndgEquCbDzC5OyVxWSGZmd2l",
    "transactionHid": "P20231110DIBK6LLZ"
  },
  "message": ""
}
```

---

## POST /checkout-subscription — Create Subscription Payment

### Additional Notes

- First charge happens immediately upon checkout
- Subsequent charges occur at 9:00 AM (UTC+8) on the same day each month
- Pre-charge notification email sent 3 days before each charge
- Failed charges trigger email to accounting contact (or company contact)

### Request

Same as single checkout, plus:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| numberOfPeriods | number | No | Total periods; omit for unlimited |

### Redirect After Response

- Production: `https://{merchantId}.oen.tw/checkout/subscription/{data.id}`
- Testing: `https://{merchantId}.testing.oen.tw/checkout/subscription/{data.id}`

---

## POST /checkout-schedule — Create Scheduled Subscription

### Additional Notes

- Charges start on the configured `startDate`
- If `startDate` is omitted, first charge happens immediately
- Charge interval is configurable (1-12 months)

### Request

Same as subscription, plus:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| paymentInterval | number | No | Months between charges (1-12, default: 1) |
| startDate | string | No | First charge date `yyyy/MM/dd` (UTC+8); omit for immediate; max 12 months ahead |

### Redirect After Response

- Production: `https://{merchantId}.oen.tw/checkout/schedule/{data.id}`
- Testing: `https://{merchantId}.testing.oen.tw/checkout/schedule/{data.id}`

---

## POST /checkout-token — Card Tokenization via 3D Secure

### Request

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| merchantId | string | Yes | Merchant domain name |
| successUrl | string | Yes | Redirect URL on success |
| failureUrl | string | Yes | Redirect URL on failure |
| customId | string | No | Custom data |
| note | string | No | Memo |

### Redirect After Response

- Production: `https://{merchantId}.oen.tw/checkout/subscription/create/{data.id}`
- Testing: `https://{merchantId}.testing.oen.tw/checkout/subscription/create/{data.id}`

### 3D Secure Test Cards

- `4000 0000 0000 2503`
- `5200 0000 0000 2151`

---

## GET /transactions/:id — Query Transaction Details

### Response

```json
{
  "code": "S0000",
  "data": {
    "id": "P20240412QJMAZNML",
    "transactionId": "2ezVvlPIKZzJxY8L2ukhEPKDJWz",
    "action": "onetime",
    "amount": 1000,
    "fee": 30,
    "paymentInfo": {
      "cardType": "Visa",
      "cardNum": "4242424242424242",
      "method": "card",
      "cardName": "王小明"
    },
    "status": "charged",
    "userId": "OEN00001",
    "userName": "王小明",
    "userEmail": "test@oen.tw",
    "orderId": "ORDER00001",
    "note": "備註",
    "createdAt": "2024-04-12T07:40:25.502Z",
    "refundAmount": 0
  },
  "message": ""
}
```

### Transaction Fields

| Field | Type | Description |
|-------|------|-------------|
| id | string | Human-readable ID (P-prefix) |
| transactionId | string | Internal transaction ID |
| action | string | `onetime` or `subscription` |
| amount | number | Transaction amount |
| fee | number | Processing fee |
| paymentInfo.cardType | string | Visa, MasterCard, etc. |
| paymentInfo.cardNum | string | Card last 4 digits |
| paymentInfo.method | string | card / cvs / linePay |
| paymentInfo.cardName | string | Cardholder name |
| status | string | initiated / charging / failed / charged / claimed / refunded |
| userId | string | Consumer ID |
| userName | string | Consumer name |
| userEmail | string | Consumer email |
| orderId | string | Order ID |
| note | string | Memo |
| createdAt | string | ISO date (UTC+0) |
| refundAmount | number | Refunded amount |
| refundedAt | string | Refund time (if refunded) |

---

## GET /transactions — List Transactions

### Query Parameters

| Param | Type | Description |
|-------|------|-------------|
| page | string | Pagination token from previous response |
| start | string | Start date filter |
| end | string | End date filter |

### Response

```json
{
  "code": "S0000",
  "data": {
    "transactions": [ ... ],
    "page": "eyJMaW1pdCI6MTAwLC..."
  },
  "message": ""
}
```

---

## GET /order/:orderId/transactions — Transactions by Order ID

Returns all transactions linked to a specific order ID. Same response format as list transactions (without pagination).

---

## GET /subscriptions/:subscriptionId — Query Subscription

### Response

```json
{
  "code": "S0000",
  "data": {
    "id": "S2024041277SVMQE5",
    "status": "ongoing",
    "period": 1,
    "startedAt": "2024-04-12T07:44:35.592Z",
    "nextChargeAt": "2024-05-11T16:00:00.000Z",
    "createdAt": "2024-04-12T07:44:35.592Z",
    "amount": 1000,
    "userId": "OEN00001",
    "userName": "王小明",
    "orderId": "ORDER00001",
    "note": "備註"
  },
  "message": ""
}
```

### Subscription Fields

| Field | Type | Description |
|-------|------|-------------|
| id | string | Subscription ID (S-prefix) |
| status | string | ongoing / cancelled / done / error / retryScheduled |
| period | number | Current period number |
| startedAt | string | Subscription start time |
| nextChargeAt | string | Next charge time |
| cancelledAt | string | Cancellation time (if cancelled) |
| reason | string | Cancellation reason (if cancelled) |
| amount | number | Charge amount per period |

---

## PUT /subscriptions/:subscriptionId — Cancel Subscription

### Request

```json
{
  "merchantId": "oentech",
  "reason": "Customer requested cancellation"
}
```

### Response

```json
{
  "code": "S0000",
  "data": {
    "id": "S202404112CYPRJPZ",
    "status": "cancelled",
    "period": 1,
    "startedAt": "2024-04-11T10:31:46.640Z",
    "cancelledAt": "2024-04-11T10:31:46.744Z",
    "reason": "客戶自行取消",
    "createdAt": "2024-04-11T10:31:46.640Z"
  },
  "message": ""
}
```

---

## POST /refunds/:transactionHid — Refund Transaction

### Important Rules

- Each transaction can only be refunded **once**
- API only supports **credit card** refunds; for CVS/ATM, use Oen CRM dashboard
- Use `transactionHid` (e.g., `P20240620ABCD1234`), NOT `transactionId`
- Minimum: NT$1, Maximum: original transaction amount

### Request

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| merchantId | string | Yes | Merchant domain name |
| amount | number | Yes | Refund amount (min 1, max original amount) |
| productDetails | array | For invoicing | Items to generate allowance (折讓) |
| remitInfo | object | CVS refund (CRM only) | Bank account details for remittance |
| reason | string | No | Refund reason |

### remitInfo (for CVS refunds via CRM)

| Field | Type | Description |
|-------|------|-------------|
| bankCode | string | Bank code |
| bankName | string | Bank name |
| branchCode | string | Branch code |
| branchName | string | Branch name |
| account | string | Bank account number |
| accountName | string | Account holder name |

### Response

```json
{
  "code": "S0000",
  "data": {
    "id": "P20240411AN3KW7BK",
    "action": "onetime",
    "amount": 1000,
    "fee": 30,
    "paymentInfo": {
      "cardType": "Visa",
      "cardNum": "4242424242424242",
      "method": "card",
      "cardName": "王小明"
    },
    "status": "refunded",
    "userId": "OEN00001",
    "userName": "王小明",
    "userEmail": "test@oen.tw",
    "orderId": "ORDER00001",
    "note": "客戶取消訂單",
    "createdAt": "2024-04-11T10:45:22.026Z",
    "refundAmount": 1000,
    "refundedAt": "2024-04-11T10:45:22.076Z"
  },
  "message": ""
}
```

---

## Integration Code Examples

### TypeScript — Single Checkout

```typescript
const response = await fetch('https://payment-api.oen.tw/checkout', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${API_TOKEN}`,
  },
  body: JSON.stringify({
    merchantId: 'your-domain',
    amount: 1000,
    currency: 'TWD',
    orderId: 'ORDER-001',
    successUrl: 'https://your-site.com/success',
    failureUrl: 'https://your-site.com/fail',
  }),
});

const result = await response.json();
if (result.code === 'S0000') {
  const checkoutUrl = `https://your-domain.oen.tw/checkout/${result.data.id}`;
  // Redirect user to checkoutUrl
}
```

### TypeScript — Query Transaction

```typescript
const response = await fetch(`https://payment-api.oen.tw/transactions/${transactionId}`, {
  method: 'GET',
  headers: {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${API_TOKEN}`,
  },
});

const result = await response.json();
// result.data contains transaction details
```

### cURL — Create Checkout

```bash
curl -X POST https://payment-api.testing.oen.tw/checkout \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "merchantId": "your-domain",
    "amount": 1000,
    "currency": "TWD",
    "orderId": "ORDER-001",
    "successUrl": "https://your-site.com/success",
    "failureUrl": "https://your-site.com/fail"
  }'
```

### Python — Subscription Checkout

```python
import requests

response = requests.post(
    'https://payment-api.oen.tw/checkout-subscription',
    headers={
        'Content-Type': 'application/json',
        'Authorization': f'Bearer {API_TOKEN}',
    },
    json={
        'merchantId': 'your-domain',
        'amount': 500,
        'currency': 'TWD',
        'orderId': 'SUB-001',
        'successUrl': 'https://your-site.com/success',
        'failureUrl': 'https://your-site.com/fail',
        'numberOfPeriods': 12,
    },
)

result = response.json()
checkout_url = f'https://your-domain.oen.tw/checkout/subscription/{result["data"]["id"]}'
```

### Express.js — Webhook Handler

```javascript
app.post('/webhook/oen-payment', (req, res) => {
  const { success, transactionHid, status, amount, orderId, action } = req.body;

  if (success && status === 'charged') {
    // Update your order status
    console.log(`Payment ${transactionHid} charged: ${amount} for order ${orderId}`);
  } else if (!success) {
    console.log(`Payment failed for order ${orderId}: ${req.body.message}`);
  }

  // Always respond 200 to acknowledge receipt
  res.status(200).json({ received: true });
});
```
