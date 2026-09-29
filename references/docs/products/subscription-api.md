---
title: "Subscription API"
url: "https://developer.oen.tw/products/subscription-api/"
---

> 來源：https://developer.oen.tw/products/subscription-api/（自動產生，請勿手動修改）

# Subscription API

Subscription API 用來經營訂閱制服務：你先建立**產品**與**方案**，把訂閱頁網址放在自己的網站，消費者在應援的訂閱頁輸入卡片完成訂閱。之後的續扣、試用、方案變更、取消與退款，都可以用 API 管理，並透過 webhook 同步狀態。

> 開始前請確認
> 
> -   **需要開通**：網域要開啟 API 串接（開發者模式），操作的 CRM 帳號也要有 Subscription API 金鑰的權限。
> -   **收單限制**：訂閱的首期扣款目前只支援部分收單機構，不符合時訂閱頁會回 422 `SA047`。開通前請先跟業務人員確認。
> -   **沒有公開的測試環境**：目前只有正式環境可以使用。

## 跟 Payment API 的定期定額差在哪

只要「每月固定金額自動扣款」，用 [Payment API 的定期定額](../developers/subscriptions.md)就夠了。需要以下功能時，再考慮 Subscription API：

|  | Payment API 定期定額 | Subscription API |
| --- | --- | --- |
| 建立方式 | 每位訂閱人各建立一次結帳頁 | 先建立產品與方案，所有人共用同一個訂閱頁網址 |
| 週期 | 每月，或每 1 到 12 個月 | 天、月、年，任意間隔 |
| 試用期 | 不支援 | 支援試用天數與試用次數限制 |
| 方案變更 | 不支援 | 支援；分級產品升級會產生補差額的付款連結 |
| 取消 | 立即取消 | 期末取消、恢復、立即終止並按日計算退款 |
| 扣款失敗 | 預設不重扣，可在 CRM 開啟重扣（最多 2 次） | 自動重試，另可產生補繳連結 |
| 訂閱人自助管理 | 無 | 有，訂閱人以 email 驗證碼登入 |
| 幣別 | 只支援 TWD | TWD |
| 金鑰 | CRM 產生的 Payment API token | 獨立的 `sub_sk_` 金鑰，可限制權限範圍 |
| Webhook | 沒有簽章 | 有簽章，17 種事件，可查投遞紀錄並手動重送 |

## 取得金鑰

1.  確認網域已開啟 API 串接（開發者模式）。新申請的商家預設就是開啟的；舊商家請洽業務人員。沒開時產生金鑰會回 `M002`。
2.  進入 CRM「訂閱管理」→「設定」→「API 金鑰」（`/crm/subscription/settings/api-keys`）。你的帳號需要 Subscription API 金鑰的權限。
3.  建立金鑰並勾選需要的權限範圍（scope）。金鑰格式是 `sub_sk_` 加 32 碼，**只會顯示一次**。
4.  在同一區的「Webhook」頁（`/crm/subscription/settings/webhooks`）設定接收網址，取得簽章密鑰（`sub_whsec_` 開頭）。

| scope | 可以做的事 |
| --- | --- |
| `read:*` | 所有查詢 |
| `write:product` | 建立、更新產品 |
| `write:plan` | 建立、更新方案 |
| `write:subscription` | 變更方案、變更期間、取消、恢復、終止、退款、補繳連結 |
| `write:customer` | 更新客戶資料 |
| `ops:webhook` | 查詢投遞紀錄、手動重送 |

-   更換金鑰後，舊金鑰會再有效 24 小時。
-   金鑰無效回 401 `X022`，權限範圍不足回 403 `X023`。

## 共通規格

-   Base URL：`https://subscription-api.oen.tw`，所有路徑都以 `/v1` 開頭。
-   每個請求帶 `Authorization: Bearer sub_sk_…`。
-   成功回應一律 HTTP 200，格式是 `{ "data": …, "paging"?: { "next": … } }`。
-   錯誤回應是 `{ "errno": "SA001", "message": "…" }`，HTTP 狀態碼依錯誤而定。程式判斷請比對 `errno`。
-   分頁：把上一頁的 `paging.next` 原封不動放進 `?page=`；沒有下一頁時是 `null`。列表每頁 50 筆。
-   ID 前綴：訂閱 `sub_`、產品 `prod_`、方案 `plan_`、客戶 `cus_`、事件 `evt_`。

### 訂閱狀態

| 狀態 | 意思 |
| --- | --- |
| `trialing` | 試用中 |
| `active` | 正常扣款中 |
| `paused` | 扣款失敗，暫停中。`nextChargeAt` 是下次重試時間 |
| `failed` | 扣款失敗且不再重試 |
| `cancelled` | 已取消（期末取消） |
| `terminated` | 已終止 |

`nextChargeAt` 是實際扣款的時間，一律是台北時間上午 9 點。

## 端點

| Method | Path | scope | 說明 |
| --- | --- | --- | --- |
| `POST` | `/v1/products` | `write:product` | 建立產品。`subscriptionType` 是 `fixedPeriod` 或 `tiered`，建立後不能改 |
| `GET` | `/v1/products` | `read:*` | 產品列表 |
| `GET` | `/v1/products/{productId}` | `read:*` | 查詢產品 |
| `PUT` | `/v1/products/{productId}` | `write:product` | 更新產品 |
| `GET` | `/v1/products/{productId}/subscription-url` | `read:*` | 取得訂閱頁網址 |
| `POST` | `/v1/products/{productId}/plans` | `write:plan` | 建立方案。`billingPeriod` 建立後不能改 |
| `GET` | `/v1/products/{productId}/plans` | `read:*` | 方案列表 |
| `PUT` | `/v1/products/{productId}/plans/{planId}` | `write:plan` | 更新方案 |
| `GET` | `/v1/products/{productId}/subscriptions` | `read:*` | 某產品的訂閱列表 |
| `GET` | `/v1/subscriptions/{id}` | `read:*` | 查詢訂閱，含產品、方案、客戶、付款與最近 100 筆操作紀錄 |
| `POST` | `/v1/subscriptions/{id}/plan-change` | `write:subscription` | 變更方案 |
| `POST` | `/v1/subscriptions/{id}/period-change` | `write:subscription` | 變更期間結束日 |
| `POST` | `/v1/subscriptions/{id}/cancel` | `write:subscription` | 期末取消 |
| `POST` | `/v1/subscriptions/{id}/resume` | `write:subscription` | 恢復已取消的訂閱 |
| `POST` | `/v1/subscriptions/{id}/terminate` | `write:subscription` | 立即終止，回應附退款試算 |
| `POST` | `/v1/subscriptions/{id}/refunds` | `write:subscription` | 終止後退款 |
| `POST` | `/v1/subscriptions/{id}/recovery-links` | `write:subscription` | 產生補繳連結，3 天內有效 |
| `GET` | `/v1/customers` | `read:*` | 客戶列表 |
| `GET` | `/v1/customers/{customerId}` | `read:*` | 查詢客戶 |
| `PUT` | `/v1/customers/{customerId}` | `write:customer` | 更新客戶姓名、電話、地址（email 不能改） |
| `GET` | `/v1/webhook-deliveries` | `ops:webhook` | 投遞紀錄 |
| `GET` | `/v1/webhook-deliveries/{deliveryId}` | `ops:webhook` | 單筆投遞紀錄 |
| `POST` | `/v1/webhook-deliveries/{deliveryId}/resend` | `ops:webhook` | 手動重送 |

### 主要欄位

**建立產品** `POST /v1/products`

| 欄位 | 必填 | 說明 |
| --- | --- | --- |
| `name` | 必填 | 最多 50 字 |
| `subscriptionType` | 必填 | `fixedPeriod` 或 `tiered` |
| `status` | 選填 | 預設 `inactive` |
| `summary` | 選填 | 最多 100 字 |
| `description` | 選填 | 產品說明 |
| `trialReuse` | 選填 | 試用可以用幾次：`unlimited`、`once_per_plan`、`once_per_product` |
| `gracePeriodDays` | 選填 | 寬限天數 |
| `basicInfoFields` | 選填 | 訂閱頁要不要收電話、地址，以及是否接受海外地址 |
| `websiteUrl`、`successRedirectUrl`、`failureRedirectUrl` | 選填 | 你的網站與導回網址，必須是 https |
| `customerServicePhone`、`customerServiceEmail` | 選填 | 顯示在訂閱頁的客服資訊 |

**建立方案** `POST /v1/products/{productId}/plans`

| 欄位 | 必填 | 說明 |
| --- | --- | --- |
| `name` | 必填 | 1 到 30 字 |
| `price` | 必填 | 整數，0 以上 |
| `billingPeriod` | 必填 | `{ "unit": "day" \| "month" \| "year", "interval": 1 以上 }` |
| `trialDays` | 選填 | 試用天數；沒帶時沿用產品的設定 |
| `description` | 選填 | 最多 1,000 字 |
| `status` | 選填 | 預設 `active` |

消費者從訂閱頁回到你的網址時，會帶上 `?subscriptionId=sub_…&result=success|failure&action=subscription_create|recovery_payment|plan_upgrade`。導回只是提示，請以 webhook 或查詢結果為準。

## Idempotency-Key

變更方案、變更期間、取消、恢復、終止、退款與 webhook 重送都**一定要帶** `Idempotency-Key`，沒帶會回 400 `SA034`。產品、方案、客戶的建立與更新，以及補繳連結，不需要帶。

-   Header 名稱請寫成 `Idempotency-Key`（或全小寫）。
-   取消、恢復、終止：同一把 key 重送時，如果訂閱已經在目標狀態，會回原本的結果；內容不同則回 409 `SA044`。
-   退款：
    -   處理中回 409 `SA025`。
    -   先前已失敗回 409 `SA026`，要再退請換一把新的 key。
    -   結果未定回 503 `SA028`，**請用同一把 key 重試**，不要換新的。

## Webhook

### 事件

`subscription_created`、`subscription_renewed`、`subscription_failed`、`subscription_recovered`、`subscription_paused`、`subscription_cancelled`、`subscription_resumed`、`subscription_terminated`、`subscription_plan_changed`、`subscription_period_changed`、`subscription_payment_method_updated`、`subscription_payment_refunded`、`subscription_trial_started`、`subscription_trial_ending`、`subscription_trial_ended`、`subscription_upcoming_charge`、`customer_updated`。

設定 webhook 時沒有指定事件，就會收到全部事件。

### 內容與 header

```json
{
  "id": "evt_…",
  "type": "subscription_renewed",
  "created": 1790000000,
  "data": {
    "subscription": { "id": "sub_…", "status": "active" },
    "paymentDetail": { "amount": 299, "currency": "twd" }
  }
}
```

Header 包含 `OenPay-Signature`、`OenPay-Event-Type`、`OenPay-Event-Id` 與 `OenPay-Delivery-Attempt`。

### 驗證簽章

格式與算法跟 Embed 相同：`OenPay-Signature: t=<unix 秒>,v1=<hex>`，用 `sub_whsec_` 密鑰對 `{t}.{原始 body}` 計算 HMAC-SHA256。伺服器端沒有規定時間差，建議拒絕超過 5 分鐘的通知。更換密鑰後 24 小時內會同時帶新舊兩個 `v1=`。

終端機視窗

```bash
# 在本機模擬一個帶簽章的通知，測試你的驗簽程式
BODY='{"id":"evt_test_0001","type":"payment_intent.succeeded","created":1790000000,"data":{}}'
T=$(date +%s)
SIG=$(printf '%s.%s' "$T" "$BODY" | openssl dgst -sha256 -hmac "$OEN_SUBSCRIPTION_WEBHOOK_SECRET" | sed 's/^.* //')

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
  if (!verifySignature(rawBody, req.header("OenPay-Signature"), process.env.OEN_SUBSCRIPTION_WEBHOOK_SECRET)) {
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
$secret = getenv('OEN_SUBSCRIPTION_WEBHOOK_SECRET');

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
    if not verify_signature(payload, request.headers.get("OenPay-Signature", ""), os.environ["OEN_SUBSCRIPTION_WEBHOOK_SECRET"]):
        abort(400)
    event = request.get_json()
    # 用 event["id"]（evt_ 開頭）判斷是否處理過；處理過就直接回 200
    return "", 200
```

### 投遞與重試

-   單次逾時 15 秒，只有 2xx 算成功，**不跟隨 3xx 轉址**。
-   失敗會自動重試 3 次，間隔約 1 分鐘、5 分鐘、30 分鐘。
-   可用 `GET /v1/webhook-deliveries` 查詢，用 `POST /v1/webhook-deliveries/{id}/resend` 手動重送。
-   同一個事件可能送達不只一次，請用事件 `id` 判斷是否處理過。

## 錯誤碼

### 共通

| errno | HTTP | 意思 |
| --- | --- | --- |
| `X006` | 400 | 欄位驗證失敗，`message` 會列出欄位與原因 |
| `X019` | 400 | `page` 對不到這個列表的資料 |
| `X028` | 400 | `page` 無法解析 |
| `X016` | 400 | 目前狀態不能建立補繳連結（只有扣款失敗且排定重試中的訂閱可以） |
| `X022` | 401 | 金鑰缺少、格式錯誤或無效 |
| `X023` | 403 | 金鑰缺少這個操作需要的 scope |
| `X011` | 404 | 路徑不存在 |

### 訂閱與方案

| errno | HTTP | 意思 |
| --- | --- | --- |
| `SA001` | 404 | 找不到訂閱，或不屬於這個商家 |
| `SA002`、`SA003`、`SA004`、`SA006` | 409 | 目前狀態不能取消、終止、恢復或變更期間 |
| `SA005` | 409 | 目前狀態不能變更方案 |
| `SA008` | 409 | 讀取後狀態已改變，請重新查詢再操作 |
| `SA009` | 409 | 因扣款失敗暫停的訂閱，請改用補繳連結 |
| `SA010` | 503 | 暫時讀不到付款資料，可以用同一把 key 重試 |
| `SA011` | 404 | 找不到方案，或不屬於這個產品 |
| `SA012` | 400 | 已經是這個方案 |
| `SA013` | 409 | 同一筆訂閱每天（台北時間）只能成功變更方案一次 |
| `SA014` | 409 | 已有進行中的方案變更 |
| `SA015` | 409 | 扣款仍在處理或結果未定。**不代表失敗**，請稍後查詢，不要重送 |
| `SA016` | 409 | 這筆變更已經完成 |
| `SA018` | 400 | 期間結束日格式錯誤 |
| `SA019` | 422 | 期間結束日必須晚於今天 |
| `SA045` | 404 | 找不到產品 |
| `SA046` | 404 | 找不到客戶 |
| `SA047` | 422 | 首期扣款的收單機構不支援 Subscription API，請洽業務人員 |

### 退款

| errno | HTTP | 意思 |
| --- | --- | --- |
| `SA007` | 409 | 訂閱尚未終止，不能退款 |
| `SA021` | 409 | 終止時沒有算出可退金額 |
| `SA022` | 409 | 金額超過剩餘可退額度 |
| `SA023` | 409 | 交易本身的可退餘額不足 |
| `SA024` | 409 | 這筆交易另有處理中的扣款 |
| `SA025` | 409 | 同一筆退款仍在處理中 |
| `SA026` | 409 | 這把 key 先前的退款已失敗，要再退請換新的 key |
| `SA027` | 502 | 金流端拒絕這筆退款。先確認交易狀態，要再退請換新的 key |
| `SA028` | 503 | 退款結果未定，請用同一把 key 重試 |

### Idempotency 與 webhook

| errno | HTTP | 意思 |
| --- | --- | --- |
| `SA034` | 400 | 沒有帶 `Idempotency-Key` |
| `SA035` | 409 | `Idempotency-Key` 已逾期，請換新的 |
| `SA044` | 409 | 同一把 key 用在內容不同的請求 |
| `SA030` | 404 | 找不到投遞紀錄 |
| `SA031` | 409 | 這筆投遞正在處理中 |
| `SA032` | 409 | 對應的 webhook 未啟用 |
| `SA033` | 409 | 事件內容已無法取得，不能重送 |
| `SA040` | 400 | 這次操作需要重新確認卡片資訊 |
| `SA041` | 400 | 目前的付款方式不支援這次操作 |
