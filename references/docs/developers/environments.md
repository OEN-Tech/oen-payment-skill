---
title: "環境與測試"
url: "https://developer.oen.tw/developers/environments/"
---

> 來源：https://developer.oen.tw/developers/environments/（自動產生，請勿手動修改）

# 環境與測試

## 兩個環境

|  | 測試環境 | 正式環境 |
| --- | --- | --- |
| API | `https://payment-api.testing.oen.tw` | `https://payment-api.oen.tw` |
| 結帳頁 | `https://{網域名稱}.testing.oen.tw/checkout/{id}` | `https://{網域名稱}.oen.tw/checkout/{id}` |
| CRM（產生 token、設定通知網址） | `https://{網域名稱}.testing.oen.tw/crm` | `https://{網域名稱}.oen.tw/crm` |
| token | 測試環境 CRM 產生 | 正式環境 CRM 產生 |
| 固定 IP 白名單 | 沒有 | **有**，要先申請，見[固定 IP 白名單](ip-allowlist.md) |
| 付款通知 | **會實際送到你設定的網址** | 會 |
| 實際扣款 | 不會，連到收單機構的測試系統 | 會 |

-   兩個環境的 token 不能互用，用錯會回 401 `A0001`。
-   兩個環境的通知網址要分別在各自的 CRM 設定。
-   測試環境帳號與網域需要請應援開設，請商家聯絡業務人員。

## 各種頁面網址

API 只回傳 `id`，結帳頁網址要自己組：

| API | 結帳頁路徑 | 有效時間 |
| --- | --- | --- |
| [`POST /checkout`](../api/checkout.md) | `/checkout/{id}` | 5 分鐘 |
| [`POST /checkout-subscription`](../api/checkout-subscription.md) | `/checkout/subscription/{id}` | 5 分鐘 |
| [`POST /checkout-schedule`](../api/checkout-schedule.md) | `/checkout/schedule/{id}` | 5 分鐘 |
| [`POST /checkout-token`](../api/checkout-token.md) | `/checkout/subscription/create/{id}` | 10 分鐘 |

有效時間從呼叫 API 的那一刻起算，不是從消費者打開頁面起算。

## 測試付款

測試環境連到收單機構的測試系統，不會真的扣款。

> 不要依賴舊文件的測試規則
> 
> 舊版 Postman 文件寫「金額大於 100 元會成功、小於 100 元會失敗」，以及幾組固定的測試卡號。這些不是應援系統的規則，實際結果依收單機構的測試系統而定，請不要依賴。

-   各網域在測試環境使用的收單設定可能不同，可以用的測試卡號請向應援的聯絡人索取。
-   到期日請填未來的日期。結帳頁會直接擋下已過期的卡片。
-   要測試逾時，讓結帳頁停留超過 5 分鐘即可，頁面會導回 `failureUrl?payment_error=V0002`。
-   超商代碼、ATM 繳費完成的流程需要應援協助模擬，請聯絡聯絡人。

## 測試付款通知

-   測試環境會把付款通知送到你在**測試環境 CRM** 設定的網址。
-   本機開發可以用 tunnel 工具取得公開的 https 網址。網址必須是 https、使用 443 port，而且可以從網際網路連到。
-   付款通知沒有「重送」按鈕，也沒有測試事件 API。要重複測試，請再建立一筆交易付款。

## 換到正式環境

1.  在正式環境 CRM 產生 token，更新伺服器設定。
2.  在正式環境 CRM 設定通知網址。
3.  把 API 網址與結帳頁網址中的 `.testing` 拿掉。
4.  確認已完成[固定 IP 白名單](ip-allowlist.md)申請。
5.  走一遍[上線檢查清單](go-live.md)。
