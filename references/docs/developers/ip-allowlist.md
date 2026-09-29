---
title: "固定 IP 白名單"
url: "https://developer.oen.tw/developers/ip-allowlist/"
---

> 來源：https://developer.oen.tw/developers/ip-allowlist/（自動產生，請勿手動修改）

# 固定 IP 白名單

> 正式環境一定要先綁定
> 
> 正式環境 `payment-api.oen.tw` 只接受已綁定的 IP，其他來源的請求一律回 HTTP 403。**測試環境沒有這個限制**，所以常見的狀況是「測試環境都正常，一上線就 403」。

## 哪些會受影響

|  | 要綁定 IP 嗎 |
| --- | --- |
| 你的伺服器呼叫 `payment-api.oen.tw` | **要** |
| 你的伺服器呼叫 `payment-api.testing.oen.tw` | 不用 |
| 消費者打開應援結帳頁付款 | 不用 |
| 應援送付款通知給你 | 不用（方向相反） |

透過已和應援串接好的合作平台收款的商家，不需要申請。

## 準備固定的對外 IP

你的伺服器呼叫 API 時，對外使用的 IP 必須固定：

-   自己的主機或 VPS：通常就是主機的公開 IP。
-   雲端服務（容器、Serverless、自動擴展的主機）：對外 IP 通常會變動，請設定 NAT Gateway 或固定出口 IP，讓所有呼叫都從固定的 IP 出去。
-   有多台伺服器、多個區域或備援機房時，每一個出口 IP 都要申請。

要確認伺服器實際的對外 IP，可以在伺服器上執行 `curl https://checkip.amazonaws.com`。

## 申請

1.  準備：網域名稱、要綁定的 IP 清單。
2.  請商家聯絡應援客服或業務人員提出申請。
3.  應援完成設定後會通知你。
4.  從伺服器呼叫一次查詢類的 API（例如[查詢交易列表](../api/list-transactions.md)），確認不再回 403。

更換主機或出口 IP 時，請**先**申請新的 IP，確認生效後再切換，避免中斷。

## 被擋下時會看到什麼

```http
HTTP/1.1 403 Forbidden

{"message":"Forbidden"}
```

-   body 只有 `message`（通常是 `Forbidden`），**沒有** `code` 欄位，和 API 自己的錯誤格式不同。
-   用這點就能分辨：有 `code: "A0001"` 是 token 的問題；沒有 `code` 的 403 是 IP 還沒綁定。

## 付款通知的來源 IP

你的防火牆需要限制來源時，請向應援索取付款通知的來源 IP。付款通知從固定的出口送出。
