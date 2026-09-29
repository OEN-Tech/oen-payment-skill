---
title: "Embed 嵌入式付款"
url: "https://developers.oentech.ai/products/embed/"
---

> 來源：https://developers.oentech.ai/products/embed/（自動產生，請勿手動修改）

# Embed 嵌入式付款

Embed 把應援的信用卡表單以 iframe 嵌進你的結帳頁。卡號只在應援的 iframe 裡處理，不會經過你的頁面或伺服器。

> 開始前請確認
> 
> -   **要先請應援開通**，商家不能自行開通。
> -   **沒有測試模式**：正式環境的金鑰打下去就是真的扣款。要測試請請應援另外準備測試環境的商家。
> -   只支援**信用卡**、只收**新台幣**，金額是 1 到 200,000 的整數。
> -   只支援付款後自動請款，不能存卡後再扣款，所以**做不了定期定額**；也**不開發票**。這些需求請用 [Payment API](../developers/quickstart.md)。

## 適合誰

| 適合 | 不適合 |
| --- | --- |
| 有自己的結帳頁，希望消費者留在自己的網站完成信用卡付款，又不想處理卡號 | 需要定期扣款、存卡扣款、電子發票，或信用卡以外的付款方式 |

## 開通與後台設定

1.  **確認線上金流已開通。** Embed 建立在線上金流之上，還沒開通的話請先完成[開通金流](https://developers.oentech.ai/merchant/activate/)。
    
2.  **請應援開通 Embed。** 聯絡負責你的業務人員。開通後，CRM「總設定」會多出一個「OenPay Embed」分頁（網址 `/crm/setting/general?tab=embed`）。 看不到這個分頁時，確認兩件事：應援已經開通 Embed、你的帳號有 API 串接相關權限（例如「金流串接管理員」角色）。
    
3.  **產生金鑰（Embed API Key）。** 按下產生後會同時拿到：
    
    -   `pk_` 開頭的 Publishable Key：放在前端，公開沒關係。
    -   `sk_` 開頭的 Secret Key：**只會顯示一次**，5 分鐘後自動從畫面清除，請立刻交給工程師保存。之後畫面上只看得到開頭幾碼。
4.  **登記允許的網域（OenPay Embed 允許的 returnUrl 網域）。** 把放付款表單的頁面與付款完成後導回頁的主機名稱都加進去。
    
5.  **建立 webhook。** 填入 https 的接收網址。建立後會顯示簽章密鑰（`whsec_` 開頭），同樣只顯示一次。也可以由工程師呼叫 `POST /v1/webhooks` 建立。
    

> 允許網域是最常見的卡關點
> 
> -   清單是空的時候，**完全無法付款**。
> -   只填主機名稱，例如 `shop.example.com`，不要加 `https://` 或路徑。
> -   比對方式是完全相同，不支援萬用字元。`example.com` 與 `www.example.com` 要各加一筆。
> -   不接受 IP、`localhost`、`.local`、`.internal`；至少要兩層網域；最多 25 筆。
> -   移除網域會立即生效，請避開營業高峰。

## 付款流程

1.  **後端**用 `sk_` 呼叫 `POST /v1/payment-intents`，拿到 `clientSecret`。
2.  **前端**用 `pk_` 與 `clientSecret` 掛上付款表單。
3.  **前端**呼叫 `confirmPayment()`，3D 驗證由 SDK 處理。成功後頁面會導向你的 `returnUrl`。
4.  **後端**收到 `payment_intent.succeeded` webhook，驗證簽章後出貨。

## 環境與網址

|  | 正式環境 |
| --- | --- |
| API | `https://embed-api.oen.tw/v1` |
| SDK | `https://static-assets.oen.tw/oenpay-sdk/v1.4.0/oenpay.umd.js` |

-   金鑰沒有測試與正式之分，正式環境的金鑰一律真實扣款。
-   要測試時，請應援準備測試環境的商家與金鑰，並改用該環境的 API 與 SDK 網址。

## 驗證

每個請求都帶 `Authorization: Bearer <金鑰>`。

| 金鑰 | 格式 | 用在 |
| --- | --- | --- |
| Publishable Key | `pk_` 加 24 碼 | 前端 SDK。只能打 SDK 用的四支端點 |
| Secret Key | `sk_` 加 32 碼 | 後端。用 `pk_` 打後端端點會回 401 |
| Webhook Secret | `whsec_` 開頭，共 54 字元 | 驗證 webhook 簽章 |

-   **重新產生金鑰**：舊金鑰會再保留 24 小時，讓你有時間部署新金鑰。
-   **金鑰外洩**：先在後台**撤銷金鑰**讓它立即失效，再產生新的一組。只按重新產生的話，外洩的舊金鑰還能再用 24 小時。撤銷到新金鑰上線之間，付款會中斷。
-   以下任一項不成立，都會回 401 `AUTH_INVALID_KEY`，只有 message 不同：金鑰有效、商家啟用中、線上金流已開通、Embed 已開通。

## 後端：建立 PaymentIntent

金額請由後端依自己的訂單計算，不要相信前端傳來的數字。

| 欄位 | 必填 | 說明 |
| --- | --- | --- |
| `amount` | 必填 | 整數，1 到 200,000 |
| `orderId` | 必填 | 1 到 255 字元，不可含 `#` 與控制字元 |
| `returnUrl` | 必填 | 付款成功後導回的網址。正式環境必須是 https，主機名稱要在允許網域清單內 |
| `currency` | 選填 | 只能是 `TWD` |
| `description` | 選填 | 最多 1,000 字元 |
| `metadata` | 選填 | 最多 20 組；key 最多 40 字元，只能用英數與底線；value 最多 500 字元；總共不超過 8 KB |
| `require3ds` | 選填 | `true` 時一律走 3D 驗證 |

終端機視窗

```bash
curl -X POST "https://embed-api.oen.tw/v1/payment-intents" \
  -H "Authorization: Bearer $OEN_EMBED_SECRET_KEY" \
  -H "Content-Type: application/json" \
  -H "Idempotency-Key: order-0001" \
  -d '{
    "amount": 1200,
    "orderId": "order-0001",
    "returnUrl": "https://shop.example.com/payment/complete"
  }'
```

回應格式是 `{ "data": { ... }, "requestId": "..." }`。`data` 就是 PaymentIntent：

-   `clientSecret`：**只在建立時回傳這一次**，交給前端使用。
-   `id`：存進你的訂單，之後查詢、退款都用它。

### PaymentIntent 的狀態

| 狀態 | 意思 |
| --- | --- |
| `created`、`requiresPaymentMethod` | 等待付款者輸入卡片 |
| `requiresAction` | 等待 3D 驗證。取消或逾時會回到 `requiresPaymentMethod`，可以用同一筆重新付款 |
| `processing` | 付款處理中 |
| `succeeded` | 付款成功（終態） |
| `failed` | 付款失敗（終態）。原因在 `lastPaymentError.code`；要重新付款請建立新的 PaymentIntent |
| `canceled` | 已取消（終態） |

停在 `processing` 超過 15 分鐘的付款，應援每 5 分鐘會自動對帳一次，所以大約 20 分鐘後再查通常就有結果。

## 前端：載入 SDK 並付款

SDK 還沒有發佈到 npm，請用 CDN 載入。正式環境建議鎖定版本並加上 SRI，`integrity` 的值取自同目錄的 `sri-hashes.json`。

```html
<script
  src="https://static-assets.oen.tw/oenpay-sdk/v1.4.0/oenpay.umd.js"
  integrity="sha384-（取自 v1.4.0/sri-hashes.json）"
  crossorigin="anonymous"></script>

<div id="payment-element"></div>
<button id="pay" disabled>付款</button>

<script>
  // clientSecret 由你的後端建立 PaymentIntent 後帶到頁面
  const oenpay = new OenPay('pk_你的PublishableKey', { locale: 'zh-TW' });
  const elements = oenpay.elements({ clientSecret });
  const paymentElement = elements.create('payment', { theme: 'light' });
  paymentElement.mount('#payment-element');
  paymentElement.on('change', (e) => {
    document.getElementById('pay').disabled = !e.valid;
  });

  async function pay() {
    const { error } = await oenpay.confirmPayment({
      elements,
      confirmParams: { returnUrl: 'https://shop.example.com/payment/complete' },
    });
    // 成功時 SDK 已經把整頁導向 returnUrl；走到這裡代表失敗
    if (error) showError(error.code, error.message);
  }
  document.getElementById('pay').addEventListener('click', pay);
</script>
```

-   想一直用最新版，可以改載 `https://static-assets.oen.tw/oenpay-sdk/v1/oenpay.umd.js`。這個網址每次發佈都會更新，**不能**加 `integrity`。
-   結帳頁必須是 https，付款 iframe 不允許嵌在 http 頁面裡。

### 導回頁

只有付款成功才會導向 `returnUrl`，網址會帶上 `payment_intent_client_secret` 與 `redirect_status`。`redirect_status` 只是提示，導回頁一定要再用 `oenpay.retrievePaymentIntent(clientSecret)` 查一次狀態。

> 出貨以 webhook 為準
> 
> 前端查到的結果只用來給消費者即時回饋。出貨請以後端收到的 `payment_intent.succeeded` 為準，出貨前再用 `GET /v1/payment-intents/{id}` 交叉確認。

## Webhook

### 事件

| 事件 | 什麼時候 |
| --- | --- |
| `payment_intent.created` | 建立 PaymentIntent |
| `payment_intent.requires_action` | 等待 3D 驗證 |
| `payment_intent.succeeded` | 付款成功（出貨依據） |
| `payment_intent.failed` | 付款失敗，原因在 `data.lastPaymentError.code` |
| `payment_intent.canceled` | 已取消 |
| `refund.created`、`refund.succeeded`、`refund.failed` | 退款 |

### 內容與 header

```json
{
  "id": "evt_0123456789abcdef01234567",
  "type": "payment_intent.succeeded",
  "api_version": "2026-06-01",
  "created": 1790000000,
  "data": { "id": "…", "status": "succeeded", "amount": 1200, "orderId": "order-0001" }
}
```

-   `data` 是事件發生時的 PaymentIntent 或 Refund，不含 `clientSecret`。
-   Header：`OenPay-Signature`、`OenPay-Event-Type`、`OenPay-Event-Id`。重試時另外帶 `OenPay-Retry-Count`，`OenPay-Event-Id` 不變。

### 驗證簽章

`OenPay-Signature` 的格式是 `t=<unix 秒>,v1=<hex>`：

1.  從 header 拆出 `t` 與所有 `v1=`。
2.  用完整的 `whsec_` 字串當 key，對 `{t}.{原始 body}` 計算 HMAC-SHA256，輸出 hex。
3.  用固定時間比較函式比對，任一個 `v1=` 相符就通過；`t` 與現在相差超過 300 秒就拒絕。

> 三個常見錯誤
> 
> -   先 `JSON.parse` 再轉回字串會改變 body，驗證簽章一定失敗。
> -   時間要用 header 的 `t`，不是 body 的 `created`。重試時兩者不同。
> -   不要用一般的字串比較。

終端機視窗

```bash
# 在本機模擬一個帶簽章的通知，測試你的驗簽程式
BODY='{"id":"evt_test_0001","type":"payment_intent.succeeded","created":1790000000,"data":{}}'
T=$(date +%s)
SIG=$(printf '%s.%s' "$T" "$BODY" | openssl dgst -sha256 -hmac "$OEN_EMBED_WEBHOOK_SECRET" | sed 's/^.* //')

curl -X POST "http://localhost:3000/webhooks/oen" \
  -H "Content-Type: application/json" \
  -H "OenPay-Signature: t=$T,v1=$SIG" \
  -d "$BODY"
```

```js
import crypto from "node:crypto";
import express from "express";

const app = express();
const TOLERANCE_SECONDS = 300;

// OenPay-Signature: t=<unix 秒>,v1=<hex>[,v1=<hex>]，簽的是 `${t}.${原始 body}`
function verifySignature(rawBody, header, secret) {
  const parts = (header ?? "").split(",").map((p) => p.trim());
  const t = Number(parts.find((p) => p.startsWith("t="))?.slice(2));
  const sigs = parts.filter((p) => p.startsWith("v1=")).map((p) => p.slice(3));
  if (!Number.isFinite(t) || sigs.length === 0) return false;
  if (Math.abs(Date.now() / 1000 - t) > TOLERANCE_SECONDS) return false;

  const expected = crypto.createHmac("sha256", secret).update(`${t}.${rawBody}`).digest();
  // 更換密鑰後 24 小時內會帶兩個 v1=，任一個相符就通過
  return sigs.some((sig) => {
    const received = Buffer.from(sig, "hex");
    return received.length === expected.length && crypto.timingSafeEqual(received, expected);
  });
}

// 驗簽要用原始 body，不要先 JSON.parse
app.post("/webhooks/oen", express.raw({ type: "application/json" }), (req, res) => {
  const rawBody = req.body.toString("utf8");
  if (!verifySignature(rawBody, req.header("OenPay-Signature"), process.env.OEN_EMBED_WEBHOOK_SECRET)) {
    return res.status(400).send("invalid signature");
  }
  const event = JSON.parse(rawBody);
  // 用 event.id（evt_ 開頭）判斷是否處理過；處理過就直接回 200
  res.sendStatus(200);
  // 回應之後再處理出貨、寄信等耗時工作
});
```

```php
<?php
$payload = file_get_contents('php://input');
$header = $_SERVER['HTTP_OENPAY_SIGNATURE'] ?? '';
$secret = getenv('OEN_EMBED_WEBHOOK_SECRET');

// OenPay-Signature: t=<unix 秒>,v1=<hex>[,v1=<hex>]，簽的是 "{t}.{原始 body}"
$t = null;
$sigs = [];
foreach (explode(',', $header) as $part) {
    [$key, $value] = array_pad(explode('=', trim($part), 2), 2, '');
    if ($key === 't') $t = (int) $value;
    if ($key === 'v1') $sigs[] = $value;
}

$expected = hash_hmac('sha256', $t . '.' . $payload, $secret);
$matched = false;
foreach ($sigs as $sig) {
    if (hash_equals($expected, $sig)) $matched = true;
}

if ($t === null || abs(time() - $t) > 300 || !$matched) {
    http_response_code(400);
    exit('invalid signature');
}

$event = json_decode($payload, true);
// 用 $event['id']（evt_ 開頭）判斷是否處理過；處理過就直接回 200
http_response_code(200);
```

```python
import hashlib
import hmac
import os
import time

from flask import Flask, abort, request

app = Flask(__name__)

# OenPay-Signature: t=<unix 秒>,v1=<hex>[,v1=<hex>]，簽的是 f"{t}.{原始 body}"
def verify_signature(payload: bytes, header: str, secret: str) -> bool:
    parts = [p.strip() for p in header.split(",")]
    t = next((p[2:] for p in parts if p.startswith("t=")), "")
    sigs = [p[3:] for p in parts if p.startswith("v1=")]
    if not t.isdigit() or not sigs:
        return False
    if abs(time.time() - int(t)) > 300:
        return False
    expected = hmac.new(secret.encode(), f"{t}.".encode() + payload, hashlib.sha256).hexdigest()
    return any(hmac.compare_digest(expected, s) for s in sigs)

@app.post("/webhooks/oen")
def oen_webhook():
    payload = request.get_data()
    if not verify_signature(payload, request.headers.get("OenPay-Signature", ""), os.environ["OEN_EMBED_WEBHOOK_SECRET"]):
        abort(400)
    event = request.get_json()
    # 用 event["id"]（evt_ 開頭）判斷是否處理過；處理過就直接回 200
    return "", 200
```

### 投遞與重試

-   單次逾時 30 秒。請先回 2xx，再處理寄信、出貨等耗時工作。
-   沒有回 2xx 會重試，最多 5 次，間隔約 1 分鐘、5 分鐘、30 分鐘、2 小時、24 小時，各有約 ±20% 的隨機誤差。
-   同一個事件可能送達不只一次，請用事件 `id` 判斷是否處理過。
-   投遞紀錄保留 30 天，可用 `GET /v1/webhooks/{id}/logs` 查詢。
-   更換密鑰（`POST /v1/webhooks/{id}/rotate-secret`）後 24 小時內，header 會同時帶新舊兩個 `v1=`。
-   沒有「發送測試事件」的 API。要測試驗證簽章程式，請用上面的 cURL 範例在本機模擬。

## 退款

Embed 的退款由後端呼叫 `POST /v1/refunds`：

| 欄位 | 必填 | 說明 |
| --- | --- | --- |
| `paymentIntentId` | 必填 | PaymentIntent 的 `id` |
| `reason` | 必填 | `duplicate`、`fraudulent` 或 `requested_by_customer` |
| `amount` | 選填 | 不帶就退剩餘全額。可以多次部分退款，上限是 `amountRefundable` |
| `metadata` | 選填 | 同 PaymentIntent |

-   付款成功後 180 天內可以退款。
-   請帶 `Idempotency-Key`，例如 `refund-訂單編號-1`。

> HTTP 200 不代表退款成功
> 
> 金流商拒絕時 HTTP 仍是 200，結果在回應 body 的 `status`（`succeeded` 或 `failed`）。收到 409 `REFUND_RECONCILIATION_REQUIRED` 或 500 時，退款可能已經送出：**不要換一把新的 Idempotency-Key 重送**，先用 `GET /v1/refunds?paymentIntentId=…` 查詢結果。退款沒有自動對帳，久未有結果請帶 `requestId` 聯絡應援。

## 冪等性與頻率限制

-   支援 `Idempotency-Key` 的端點：建立 PaymentIntent、建立退款、capture，以及 SDK 代打的 confirm。key 是 1 到 255 個 ASCII 可見字元。
    -   同一把 key 重送會拿到第一次的回應，header 帶 `Idempotency-Replayed: true`。
    -   前一次處理超過 5 分鐘沒有結果，會重新處理；記錄保留 24 小時。
    -   同一把 key 用在不同內容或端點，會回 422 `IDEMPOTENCY_KEY_REUSED`。
-   頻率限制：
    -   每把 Secret Key 每分鐘 500 次。超過回 429 `AUTH_RATE_LIMITED`，請依 `Retry-After` 等待。
    -   Publishable Key：每個 IP 每分鐘 30 次，每把每分鐘 60 次。
-   另外還有一層防火牆上限：**同一個 IP 每 5 分鐘最多 100 個請求**，每把 Publishable Key 每 5 分鐘最多 600 個請求。超過會直接回 403，body 不是一般的錯誤格式，也沒有 `Retry-After`。批次對帳或大量補查時，要自己把請求分散在時間上。

## 錯誤

錯誤格式：

```json
{
  "error": { "code": "INVALID_AMOUNT", "message": "（錯誤說明）", "field": "amount" },
  "requestId": "req_…"
}
```

程式判斷請比對 `code`，`message` 的文字可能調整。回報問題時附上 `requestId`，回應 header 的 `X-Request-Id` 也是同一個值。

| HTTP | 錯誤碼 | 意思與處理 |
| --- | --- | --- |
| 400 | `INVALID_REQUEST`、`INVALID_AMOUNT`、`INVALID_CURRENCY`、`METADATA_LIMIT_EXCEEDED` | 參數不符規則，看 `field` 與 `message` 修正 |
| 400 | `MERCHANT_NOT_CONFIGURED` | 商家的金流設定不完整，請聯絡應援。不是卡片問題 |
| 400 | `PAYMENT_INTENT_ALREADY_SUCCEEDED`、`PAYMENT_INTENT_CANCELED` | 已付款或已取消，不能再做這個動作 |
| 400 | `REFUND_AMOUNT_EXCEEDED`、`REFUND_WINDOW_EXPIRED` | 超過可退金額，或超過付款後 180 天 |
| 401 | `AUTH_INVALID_KEY` | 金鑰缺少、錯誤或已撤銷；或用 `pk_` 打了後端端點；或商家尚未開通 Embed |
| 402 | `CARD_*`、`3DS_*` | 付款失敗，見下表 |
| 403 | `FORBIDDEN_ORIGIN`、`DOMAIN_NOT_REGISTERED` | 結帳頁的主機名稱不在允許網域清單內 |
| 404 | `PAYMENT_INTENT_NOT_FOUND`、`REFUND_NOT_FOUND` 等 | 資源不存在，或不屬於這把金鑰的商家 |
| 409 | `IDEMPOTENCY_KEY_IN_PROGRESS`、`REFUND_IN_PROGRESS` | 同一筆正在處理，稍後用同一把 key 重送 |
| 409 | `REFUND_RECONCILIATION_REQUIRED` | 退款結果不明，不可換 key 重送，先查詢 |
| 422 | `IDEMPOTENCY_KEY_REUSED` | 同一把 key 用在不同內容或端點 |
| 429 | `AUTH_RATE_LIMITED` | 超過頻率限制，依 `Retry-After` 等待 |
| 500 | `INTERNAL_ERROR` | 結果未知。付款或退款可能已經發生，先查狀態，不要直接重來 |

### 付款失敗的原因

這些值會出現在前端 SDK 的錯誤、`payment_intent.failed` webhook 與 `lastPaymentError.code`。請不要把內部訊息原樣轉給付款者，可以參考右欄的文案。

| 錯誤碼 | 原因 | 建議對付款者顯示 |
| --- | --- | --- |
| `CARD_DECLINED` | 發卡銀行拒絕 | 發卡銀行拒絕這筆交易，請改用其他卡片或聯絡發卡銀行 |
| `CARD_NOT_SUPPORTED` | 商家沒有開通國外卡或這種卡別 | 這張卡目前無法使用，請改用其他卡片 |
| `CARD_INSUFFICIENT_FUNDS` | 額度不足 | 卡片額度不足，請改用其他卡片 |
| `CARD_EXPIRED` | 卡片過期 | 卡片已過期，請改用其他卡片 |
| `CARD_INVALID_NUMBER` | 卡號無效 | 卡號有誤，請重新確認 |
| `CARD_INVALID_CVV` | 安全碼錯誤 | 安全碼有誤，請重新確認 |
| `CARD_RISK_DECLINED` | 未通過風險控管 | 這筆交易無法完成，請改用其他卡片 |
| `3DS_FAILED` | 3D 驗證未通過 | 銀行安全驗證未通過，請重新付款或改用其他卡片 |
| `3DS_CANCELED` | 付款者在驗證頁按了取消 | 您已取消銀行安全驗證，要繼續請重新付款 |
| `3DS_TIMEOUT` | 3D 驗證逾時 | 銀行安全驗證逾時，請重新付款 |

## 端點一覽

後端用 Secret Key 呼叫：

| Method | Path | 用途 |
| --- | --- | --- |
| `POST` | `/v1/payment-intents` | 建立 PaymentIntent |
| `GET` | `/v1/payment-intents` | 列表，可用 `status`、`createdGte`、`createdLte` 篩選，`limit` 1 到 100 |
| `GET`、`PATCH` | `/v1/payment-intents/{id}` | 查詢；更新（只能改 `metadata`） |
| `POST` | `/v1/payment-intents/{id}/cancel` | 取消 |
| `POST` | `/v1/refunds` | 建立退款 |
| `GET` | `/v1/refunds`、`/v1/refunds/{id}` | 查詢退款 |
| `POST`、`GET` | `/v1/webhooks` | 建立、列出 webhook |
| `GET`、`PATCH`、`DELETE` | `/v1/webhooks/{id}` | 管理 webhook |
| `GET` | `/v1/webhooks/{id}/logs` | 投遞紀錄 |
| `POST` | `/v1/webhooks/{id}/rotate-secret` | 更換簽章密鑰 |

`/v1/tokens`、`/v1/confirm`、`/v1/payment-intents/{id}/status` 與 `/v1/3ds/*` 由 SDK 代為呼叫，後端不需要處理。

## 測試

在測試環境的商家上測試。到期日填未來任一日期，安全碼任意三碼：

| 卡號 | 結果 |
| --- | --- |
| `4000000000000002` | 直接成功 |
| `4000010000000010` | 跳出 3D 驗證，驗證後成功 |

-   要確定走到 3D 驗證，建立 PaymentIntent 時帶 `require3ds: true`。
-   測試環境另有 `POST /v1/3ds/simulate`，可以不經過驗證頁，直接把付款推到成功、失敗、取消或逾時，方便測試導回頁與 webhook。正式環境沒有這支 API。

## 上線前檢查

-   Secret Key 與 Webhook Secret 只放在後端環境變數或密鑰管理服務，沒有進版本控制。
-   正式站的主機名稱已加入允許網域清單。
-   Webhook 接收端是 https、會驗證簽章、會用事件 `id` 判斷是否重複。
-   出貨以 `payment_intent.succeeded` 為準，出貨前再用 API 確認。
-   建立 PaymentIntent 與退款都帶 `Idempotency-Key`。
-   退款流程會檢查回應 body 的 `status`，不是只看 HTTP 200。
-   付款或退款收到 500 時，先查狀態，不直接重來。
-   在測試環境走過付款（含 3D 驗證成功與取消）、退款與 webhook。
