---
title: "快速開始"
url: "https://developers.oentech.ai/developers/quickstart/"
---

> 來源：https://developers.oentech.ai/developers/quickstart/（自動產生，請勿手動修改）

# 快速開始

這一頁帶你在測試環境走完一筆單次付款：建立結帳 → 消費者付款 → 收到付款通知 → 回查確認。

## 開始前

-   **網域名稱**：例如應援頁是 `ming.oen.tw`，網域名稱就是 `ming`。以下範例都用 `ming`，請換成你的。
-   **測試環境的 token**：在測試環境 CRM（`https://{網域名稱}.testing.oen.tw/crm`）的「總設定」→「開發者」→「應援金流設定」產生。還沒有測試環境帳號請請商家聯絡應援。詳見[交給工程師串接前的準備](https://developers.oentech.ai/merchant/api-access/)。
-   **能接收 HTTPS 的網址**：付款通知會送到這裡。本機開發可以用 tunnel 工具取得公開的 https 網址，再填到 CRM 的「交易資料回傳網址位置」。

> 注意
> 
> API 只能從你的伺服器呼叫。token 就像密碼，請放在伺服器的環境變數，不要放進前端程式或版本控制。

## 1. 設定 token

終端機視窗

```bash
export OEN_API_TOKEN="貼上測試環境的 token"
export OEN_MERCHANT_ID="ming"
```

## 2. 建立結帳

在消費者按下「付款」時，由你的伺服器呼叫 `POST /checkout`。三個重點：

-   `productDetails` **必填**，各品項「數量 × 單價」的合計必須等於 `amount`。
-   回應不會給結帳頁網址，要用 `data.id` 自己組：`https://{網域名稱}.testing.oen.tw/checkout/{id}`（正式環境沒有 `.testing`）。
-   結帳頁從建立起 **5 分鐘內**有效，請建立後立刻把消費者導過去。

終端機視窗

```bash
curl -X POST "https://payment-api.testing.oen.tw/checkout" \
  -H "Authorization: Bearer $OEN_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "merchantId": "ming",
    "amount": 1200,
    "orderId": "A20260928001",
    "successUrl": "https://shop.example.com/payment/success?order=A20260928001",
    "failureUrl": "https://shop.example.com/payment/failure?order=A20260928001",
    "productDetails": [
      { "productionCode": "SKU-001", "description": "手沖咖啡豆 200g", "quantity": 2, "unit": "包", "unitPrice": 600 }
    ]
  }'
```

```js
const API = "https://payment-api.testing.oen.tw";
const CHECKOUT_HOST = `https://${process.env.OEN_MERCHANT_ID}.testing.oen.tw`;

export async function createCheckout(order) {
  const res = await fetch(`${API}/checkout`, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${process.env.OEN_API_TOKEN}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      merchantId: process.env.OEN_MERCHANT_ID,
      amount: order.total, // 必須等於下面品項的合計
      orderId: order.id,
      successUrl: `https://shop.example.com/payment/success?order=${order.id}`,
      failureUrl: `https://shop.example.com/payment/failure?order=${order.id}`,
      productDetails: order.items.map((item) => ({
        productionCode: item.sku,
        description: item.name,
        quantity: item.quantity,
        unit: item.unit,
        unitPrice: item.price,
      })),
    }),
  });

  const result = await res.json();
  if (result.code !== "S0000") {
    throw new Error(`${result.code} ${result.message}`);
  }

  // 把 id 與 transactionHid 存進你的訂單，之後回查與退款會用到
  await saveOenTransaction(order.id, result.data.id, result.data.transactionHid);
  return `${CHECKOUT_HOST}/checkout/${result.data.id}`;
}
```

```php
<?php
function createCheckout(array $order): string
{
    $merchantId = getenv('OEN_MERCHANT_ID');
    $ch = curl_init('https://payment-api.testing.oen.tw/checkout');
    curl_setopt_array($ch, [
        CURLOPT_POST => true,
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_HTTPHEADER => [
            'Authorization: Bearer ' . getenv('OEN_API_TOKEN'),
            'Content-Type: application/json',
        ],
        CURLOPT_POSTFIELDS => json_encode([
            'merchantId' => $merchantId,
            'amount' => $order['total'], // 必須等於品項合計
            'orderId' => $order['id'],
            'successUrl' => 'https://shop.example.com/payment/success?order=' . $order['id'],
            'failureUrl' => 'https://shop.example.com/payment/failure?order=' . $order['id'],
            'productDetails' => array_map(fn ($item) => [
                'productionCode' => $item['sku'],
                'description' => $item['name'],
                'quantity' => $item['quantity'],
                'unit' => $item['unit'],
                'unitPrice' => $item['price'],
            ], $order['items']),
        ]),
    ]);

    $result = json_decode(curl_exec($ch), true);
    if (($result['code'] ?? '') !== 'S0000') {
        throw new RuntimeException(($result['code'] ?? 'HTTP') . ' ' . ($result['message'] ?? ''));
    }

    // 把 id 與 transactionHid 存進你的訂單
    saveOenTransaction($order['id'], $result['data']['id'], $result['data']['transactionHid']);
    return "https://{$merchantId}.testing.oen.tw/checkout/{$result['data']['id']}";
}

header('Location: ' . createCheckout($order));
```

```python
import os
import requests

API = "https://payment-api.testing.oen.tw"
MERCHANT_ID = os.environ["OEN_MERCHANT_ID"]

def create_checkout(order: dict) -> str:
    res = requests.post(
        f"{API}/checkout",
        headers={"Authorization": f"Bearer {os.environ['OEN_API_TOKEN']}"},
        json={
            "merchantId": MERCHANT_ID,
            "amount": order["total"],  # 必須等於品項合計
            "orderId": order["id"],
            "successUrl": f"https://shop.example.com/payment/success?order={order['id']}",
            "failureUrl": f"https://shop.example.com/payment/failure?order={order['id']}",
            "productDetails": [
                {
                    "productionCode": item["sku"],
                    "description": item["name"],
                    "quantity": item["quantity"],
                    "unit": item["unit"],
                    "unitPrice": item["price"],
                }
                for item in order["items"]
            ],
        },
        timeout=30,
    )
    result = res.json()
    if result.get("code") != "S0000":
        raise RuntimeError(f"{result.get('code')} {result.get('message')}")

    # 把 id 與 transactionHid 存進你的訂單
    save_oen_transaction(order["id"], result["data"]["id"], result["data"]["transactionHid"])
    return f"https://{MERCHANT_ID}.testing.oen.tw/checkout/{result['data']['id']}"
```

回應：

```json
{
  "code": "S0000",
  "data": { "id": "2HhndgEquCbDzC5OyVxWSGZmd2l", "transactionHid": "P20260928AB12CD34" },
  "message": ""
}
```

-   `id`：組結帳頁網址，也是之後付款通知與回查用的 id。
-   `transactionHid`：`P` 開頭的交易編號，退款與 CRM 搜尋用這個。

## 3. 把消費者導到結帳頁

把消費者導到 `https://ming.testing.oen.tw/checkout/2HhndgEquCbDzC5OyVxWSGZmd2l`。消費者付款後：

-   成功時回到 `successUrl`，**網址不會帶任何參數**，所以範例把訂單編號放在自己的網址裡。
-   失敗時回到 `failureUrl`，網址加上 `payment_error`，例如 `&payment_error=T0004`。

> 不要只靠導回來判斷付款成功
> 
> 消費者可能付完款就關掉視窗，永遠不會回到你的頁面；`successUrl` 也可以被任何人直接打開。**出貨一律以付款通知與回查結果為準。**

## 4. 接收付款通知並回查

付款完成後，應援會把結果 `POST` 到你在 CRM 設定的網址。**付款通知沒有簽章**，任何人都能偽造，所以收到後一定要用 `id` 呼叫 `GET /transactions/{id}` 回查，以查到的結果為準。

終端機視窗

```bash
# 用付款通知裡的 id 回查
curl "https://payment-api.testing.oen.tw/transactions/2HhndgEquCbDzC5OyVxWSGZmd2l" \
  -H "Authorization: Bearer $OEN_API_TOKEN"
```

```js
import express from "express";

const app = express();
const PAID = new Set(["charged", "claimed"]);

app.post("/webhooks/oen", express.json(), (req, res) => {
  // 先回 200：應援每次最多等 10 秒，逾時會重送
  res.sendStatus(200);

  const event = req.body;
  if (event.purpose !== "charge") return; // token 等其他通知另外處理
  handleCharge(event.id).catch((err) => console.error("OEN webhook", err));
});

async function handleCharge(id) {
  // 不相信通知內容，一律回查
  const res = await fetch(`https://payment-api.testing.oen.tw/transactions/${encodeURIComponent(id)}`, {
    headers: { Authorization: `Bearer ${process.env.OEN_API_TOKEN}` },
  });
  const result = await res.json();
  if (result.code !== "S0000") throw new Error(`${result.code} ${result.message}`);

  const txn = result.data;
  // 確認是你建立的那一筆：比對訂單編號與金額
  const order = await findOrderByOenId(txn.transactionId);
  if (!order || order.total !== txn.amount) return;

  if (PAID.has(txn.status)) await markOrderPaid(order.id, txn); // 同一筆重複呼叫也要安全
  else if (txn.status === "failed") await markOrderFailed(order.id, txn);
  // charging：超商、ATM 等待繳費，等下一則通知
}

app.listen(3000);
```

```php
<?php
// 先回 200：應援每次最多等 10 秒，逾時會重送
$event = json_decode(file_get_contents('php://input'), true);
http_response_code(200);
if (function_exists('fastcgi_finish_request')) fastcgi_finish_request();

if (($event['purpose'] ?? '') !== 'charge') exit;

// 不相信通知內容，一律回查
$ch = curl_init('https://payment-api.testing.oen.tw/transactions/' . rawurlencode($event['id']));
curl_setopt_array($ch, [
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_HTTPHEADER => ['Authorization: Bearer ' . getenv('OEN_API_TOKEN')],
]);
$result = json_decode(curl_exec($ch), true);
if (($result['code'] ?? '') !== 'S0000') exit;

$txn = $result['data'];
$order = findOrderByOenId($txn['transactionId']);
if (!$order || $order['total'] !== $txn['amount']) exit;

if (in_array($txn['status'], ['charged', 'claimed'], true)) {
    markOrderPaid($order['id'], $txn); // 同一筆重複呼叫也要安全
} elseif ($txn['status'] === 'failed') {
    markOrderFailed($order['id'], $txn);
}
```

```python
import os
import threading

import requests
from flask import Flask, request

app = Flask(__name__)
PAID = {"charged", "claimed"}

def handle_charge(transaction_id: str) -> None:
    # 不相信通知內容，一律回查
    res = requests.get(
        f"https://payment-api.testing.oen.tw/transactions/{transaction_id}",
        headers={"Authorization": f"Bearer {os.environ['OEN_API_TOKEN']}"},
        timeout=30,
    )
    result = res.json()
    if result.get("code") != "S0000":
        return
    txn = result["data"]
    order = find_order_by_oen_id(txn["transactionId"])
    if not order or order["total"] != txn["amount"]:
        return
    if txn["status"] in PAID:
        mark_order_paid(order["id"], txn)  # 同一筆重複呼叫也要安全
    elif txn["status"] == "failed":
        mark_order_failed(order["id"], txn)

@app.post("/webhooks/oen")
def oen_webhook():
    event = request.get_json(silent=True) or {}
    if event.get("purpose") == "charge":
        # 放到背景處理，先回 200：應援每次最多等 10 秒
        threading.Thread(target=handle_charge, args=(event["id"],)).start()
    return "", 200
```

## 5. 付款測試

打開結帳頁，用測試卡付款，確認：

-   你的伺服器收到付款通知，回查的 `status` 是 `charged`。
-   訂單狀態有更新。
-   在 CRM「金流管理」→「金流列表」看得到這筆交易（類型是「現金購買」）。

測試卡與測試環境的注意事項見[環境與測試](environments.md)。

## 接下來

-   [單次付款](one-time.md)：付款方式、發票、結帳頁逾時與重新付款。
-   [付款通知](webhooks.md)：重送規則、同一筆的多則通知、沒收到通知時怎麼補。
-   [錯誤處理](errors.md)：哪些錯誤可以重試，付款結果不明時怎麼辦。
-   上線前走一遍[上線檢查清單](go-live.md)，並申請[固定 IP 白名單](ip-allowlist.md)。
