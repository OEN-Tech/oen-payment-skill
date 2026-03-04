---
name: oen-payment
description: Oen Payment (應援金流) integration assistant. Helps developers integrate payment checkout, subscriptions, refunds, and transaction queries via the Oen Payment REST API and MCP server. Use when the user mentions "oen payment", "應援金流", "oen 金流", payment checkout with oen, oen subscription, oen refund, oen transaction, or wants to set up the oen-payment MCP server. Also trigger when code imports or references oen-payment, payment-api.oen.tw, or @OEN-Tech/oen-payment-mcp-server.
---

# Oen Payment Integration Assistant

Help developers integrate with the Oen Payment (應援金流) REST API — a unified payment gateway supporting credit cards, LINE Pay, and CVS (convenience store) payments.

## Usage

The user typed: $ARGUMENTS

## Capabilities

This skill helps with:
1. **API Integration** — Generate code to call Oen Payment REST endpoints (checkout, subscriptions, refunds, queries)
2. **MCP Server Setup** — Guide setup of the `@OEN-Tech/oen-payment-mcp-server` for AI-assisted payment operations
3. **Troubleshooting** — Diagnose errors using response codes, test card scenarios, and webhook debugging
4. **Code Generation** — Produce working integration code in TypeScript, JavaScript, Python, or cURL

## Quick Reference

### API Endpoints

| Environment | Base URL |
|-------------|----------|
| Production  | `https://payment-api.oen.tw` |
| Testing     | `https://payment-api.testing.oen.tw` |

### Authentication

All requests require:
```
Content-Type: application/json
Authorization: Bearer {token}
```
Token is obtained from the Oen CRM dashboard. Testing environment tokens and production tokens are separate.

### Core API Operations

| Operation | Method | Endpoint | Description |
|-----------|--------|----------|-------------|
| Checkout (single) | POST | `/checkout` | Create one-time payment page |
| Checkout (subscription) | POST | `/checkout-subscription` | Create recurring payment |
| Checkout (scheduled) | POST | `/checkout-schedule` | Create future-dated recurring payment |
| Token via 3D | POST | `/checkout-token` | Save card via 3D Secure verification |
| Get Transaction | GET | `/transactions/:id` | Query transaction by ID or HID |
| List Transactions | GET | `/transactions?page&start&end` | List all transactions with pagination |
| Transactions by Order | GET | `/order/:orderId/transactions` | Find transactions by order ID |
| Get Subscription | GET | `/subscriptions/:subscriptionId` | Query subscription details |
| Cancel Subscription | PUT | `/subscriptions/:subscriptionId` | Cancel recurring payment |
| Refund | POST | `/refunds/:transactionHid` | Refund a transaction (card only via API) |

### Checkout URLs (redirect user after API call)

After calling the checkout API, redirect the user's browser to:

| Type | URL Pattern |
|------|------------|
| Single payment | `https://{merchantId}.{env}.oen.tw/checkout/{data.id}` |
| Subscription | `https://{merchantId}.{env}.oen.tw/checkout/subscription/{data.id}` |
| Scheduled subscription | `https://{merchantId}.{env}.oen.tw/checkout/schedule/{data.id}` |
| Token (3D) | `https://{merchantId}.{env}.oen.tw/checkout/subscription/create/{data.id}` |

For production, omit the `{env}.` portion (e.g., `https://{merchantId}.oen.tw/checkout/{id}`).

### Minimum Checkout Request

```json
{
  "merchantId": "your-domain",
  "amount": 1000,
  "currency": "TWD",
  "orderId": "ORDER00001",
  "successUrl": "https://your-site.com/success",
  "failureUrl": "https://your-site.com/fail"
}
```

### Payment Methods

| Method | Key | Notes |
|--------|-----|-------|
| Credit Card | (default) | VISA, Mastercard, JCB |
| CVS | `"cvs"` | Convenience store code (FamilyMart only) |
| LINE Pay | `"linePay"` | Requires application; set LINE Pay token in CRM after approval |

Pass non-default methods via `allowedPaymentMethods` array in checkout request. Enable 3D Secure with `use3d: true`.

### Subscription Specific Fields

| Field | Type | Description |
|-------|------|-------------|
| `numberOfPeriods` | number | Total periods; omit for unlimited |
| `paymentInterval` | number | Months between charges (1-12), default 1 |
| `startDate` | string | `yyyy/MM/dd` (UTC+8); omit to charge immediately |

### Refund Rules

- Each transaction can only be refunded **once** via API
- API refund only supports **credit card** transactions
- For CVS/ATM refunds, use the Oen CRM dashboard
- Use `transactionHid` (e.g., `P20240620ABCD1234`), NOT `transactionId`
- Minimum refund: NT$1, maximum: original transaction amount
- If the original transaction had an invoice, provide `productDetails` for the allowance

### Refund Request

```json
{
  "merchantId": "your-domain",
  "amount": 1000,
  "reason": "Customer requested cancellation"
}
```

For CVS refunds (via CRM only), `remitInfo` is required with bank details.

### Response Codes

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

### Transaction Status Flow

```
initiated → charging → charged → (refunding → refunded)
                 ↓
               failed
```

| Status | Description |
|--------|-------------|
| `initiated` | Payment intent created |
| `charging` | Payment in progress |
| `charged` | Payment successful |
| `claimed` | Payment successful (LINE Pay) |
| `failed` | Payment declined |
| `refunded` | Refund completed |

### Test Card Numbers

| Card Number | Purpose |
|-------------|---------|
| `4242 4242 4242 4242` | Successful payment |
| `4000 0000 0000 2503` | Triggers 3D Secure |
| `5200 0000 0000 2151` | Triggers 3D Secure |
| `4012 8888 1888 8333` | Triggers failure |

**Testing tip:** Amount > 100 = success scenario, Amount < 100 = failure scenario.

### Webhook

Set the webhook endpoint in CRM. Oen sends POST with transaction result:

| Field | Type | Description |
|-------|------|-------------|
| `merchantId` | string | Your merchant ID |
| `success` | boolean | Transaction result |
| `id` (transactionId) | string | Transaction ID |
| `transactionHid` | string | Human-readable ID (e.g., P20240517VRTJYBAJ) |
| `status` | string | initiated/charging/failed/charged/claimed |
| `action` | string | onetime/subscription |
| `amount` | number | Transaction amount |
| `currency` | string | Currency code |
| `orderId` | string | Your order ID (if provided) |
| `paymentMethod` | string | card / atm / cvs / linePay |
| `subscriptionId` | string | Subscription ID (if recurring) |
| `period` | number | Current period (if recurring) |
| `customId` | string | Your custom data (if provided) |

Webhook retries 3 times on failure (2s, 4s, 6s intervals).

Failure redirects append error code: `https://your-site.com/fail?payment_error=V0001`

### MCP Server Setup

Install the Oen Payment MCP server for AI-assisted payment operations:

```json
{
  "mcpServers": {
    "oen-payment": {
      "command": "npx",
      "args": [
        "-y",
        "@OEN-Tech/oen-payment-mcp-server@latest",
        "--token=YOUR_API_TOKEN",
        "--merchantId=YOUR_MERCHANT_ID",
        "--env=testing"
      ]
    }
  }
}
```

**Pre-requisite:** Configure npm to access GitHub Packages:
```bash
echo "@OEN-Tech:registry=https://npm.pkg.github.com" >> ~/.npmrc
echo "//npm.pkg.github.com/:_authToken=YOUR_GITHUB_TOKEN" >> ~/.npmrc
```

The MCP server provides 11 tools: `checkout_link`, `get_transaction`, `subscription_checkout`, `scheduled_subscription_checkout`, `exchange_token_by_3d`, `get_subscription`, `get_transactions`, `get_transactions_by_order_id`, `cancel_subscription`, `read_oen_docs`, `get_config`.

## Workflow

1. **Understand the request**: Determine if the user needs checkout, subscription, refund, query, or setup help.

2. **For API integration code**:
   - Ask which language (TypeScript/JavaScript/Python/cURL) if not specified
   - Generate complete, working code with proper error handling
   - Include the correct endpoint, headers, and request body
   - Always include `merchantId` in request bodies
   - For checkout flows, show both the API call AND the redirect URL construction

3. **For MCP server setup**:
   - Guide through GitHub Packages auth setup
   - Provide the MCP client configuration JSON
   - Explain the 3 required parameters: token, merchantId, env

4. **For troubleshooting**:
   - Reference the response codes table
   - Check transaction status via GET endpoint
   - For webhook issues: verify endpoint is set in CRM, check retry behavior
   - For refund issues: confirm card-only limitation, check transactionHid format

5. **For detailed API documentation**: Read `references/api-docs.md` for complete request/response schemas and examples.

## Important Notes

- All date fields are ISO 8601 in UTC+0
- List endpoints return 50 items per page; use the `page` token from the previous response for pagination
- `merchantId` is your domain name (e.g., if your page is `https://ming.oen.tw`, use `ming`)
- Non-required fields are omitted from responses when empty (no null values)
- Invoice-related fields (`productDetails`, `userName`, `userEmail`) are required only when issuing invoices
