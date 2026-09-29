---
title: "付款通知（webhook）"
url: "https://developer.oen.tw/developers/webhooks/"
---

> 來源：https://developer.oen.tw/developers/webhooks/（自動產生，請勿手動修改）

# 付款通知（webhook）

付款結果確定時，應援會 `POST` 一則通知到你的伺服器。請把它當成「提醒你去查」，**以回查的結果為準**。

## 設定網址

通知網址只能在 CRM 設定，API 請求沒有這個欄位：

-   位置：CRM「總設定」→「開發者」→「應援金流設定」→「交易資料回傳網址位置」。
-   必須是 `https://`、使用 443 port，而且可以從網際網路連到。內部網址、私有 IP 會被擋下。
-   測試環境與正式環境分別設定。
-   **沒有設定網址的期間，通知會直接略過**，之後補設也不會補送。

## 什麼時候會送

| 情境 | purpose | status |
| --- | --- | --- |
| 信用卡、Apple Pay 付款成功或失敗 | `charge` | `charged`、`claimed` 或 `failed` |
| 3D 驗證開始後 10 分鐘沒完成 | `charge` | `failed`（`message: 3DS_ABANDONED`） |
| 超商代碼、ATM 取號 | `charge` | `charging`（沒有 `success`） |
| 超商代碼、ATM 繳費完成 | `charge` | `charged` 或 `claimed` |
| 超商代碼、ATM 逾期未繳 | `charge` | `failed`（`message: PAYMENT_EXPIRED`） |
| LINE Pay 等待確認、確認結果 | `charge` | `charging`，之後是最終結果 |
| 定期定額每一期（含重扣） | `charge` | 同上，`action: subscription` |
| 綁卡頁完成或失敗 | `token` | — |
| 預約定期定額結帳完成或失敗 | `schedule_subscription` | — |
| 退款、定期定額取消、重扣排定或用完 | `refund`、`subscription_cancelled`、`subscription_retry` | 需請應援開啟 |

**不會**送通知的情況：

-   消費者沒有付款就離開，交易停在 `initiated`。
-   [用 token 扣款](../api/token-transactions.md)、[用 token 建立定期定額](../api/token-subscriptions.md)的第一期。結果以 API 回應為準。
-   付款前的檢查就失敗（例如金額超出付款方式的範圍）。

每一種通知的欄位見[付款通知內容](../api/objects/webhook.md)。

## 送出規則

| 項目 | 規則 |
| --- | --- |
| 格式 | `POST`，`Content-Type: application/json` |
| 逾時 | 每次 10 秒 |
| 成功的條件 | 回應 HTTP 2xx。不看回應內容 |
| 轉址 | 不跟隨。回 3xx 會被當成失敗 |
| 次數 | **最多 3 次**，間隔約 2 秒、4 秒 |
| 3 次都失敗 | **不會再送**，也沒有後台重送功能 |
| 順序 | 不保證 |

> 3 次都失敗就不會再送
> 
> 短暫的部署或當機，就可能漏掉通知。請一定要有下面的[補救機制](#%E6%B2%92%E6%94%B6%E5%88%B0%E9%80%9A%E7%9F%A5%E6%99%82)。

## 確認通知的真假

> 付款通知沒有簽章
> 
> 付款通知沒有簽章，任何人都可以偽造一則送到你的網址。**不要直接相信通知的內容。**

1.  收到通知，先回 HTTP 200。
2.  用 body 的 `id`（27 字元）呼叫 [`GET /transactions/{id}`](../api/get-transaction.md)。
3.  確認查到的交易屬於你的訂單：比對 `orderId` 與 `amount`。
4.  依查到的 `status` 更新訂單。

-   剛付款完成的極短時間內，查到的可能還是舊狀態。查到 `charging` 或 `initiated` 時，隔幾秒再查一次。
-   `token` 通知沒有 API 可以回查。請確認 `id` 是你剛建立的[綁卡頁](../api/checkout-token.md)，並核對 `customId`。
-   程式範例見[快速開始](quickstart.md#4-%E6%8E%A5%E6%94%B6%E4%BB%98%E6%AC%BE%E9%80%9A%E7%9F%A5%E4%B8%A6%E5%9B%9E%E6%9F%A5)。

## 同一筆交易的多則通知

-   超商代碼、ATM、LINE Pay 會先收到 `charging`，之後才收到結果，兩則的 `id` 相同。
-   通知可能重複送達，也可能順序顛倒。
-   通知沒有事件編號，所以不能用「收過這個 id」判斷重複。請以**回查到的狀態**決定要做什麼，並讓「標記為已付款」這類動作重複執行也安全。

## 回應要快

-   應援每次只等 10 秒。請先回 200，再把回查、出貨、寄信等工作放到背景處理。
-   不要回 3xx，也不要讓網址需要登入。
-   防火牆有擋外部連線時，請向應援索取付款通知的來源 IP。

## 沒收到通知時

請在你的系統排一個定期工作，處理「超過一段時間還沒有結果」的訂單：

1.  找出建立超過 15 分鐘、還沒有最終結果的訂單。
2.  用 [`GET /order/{orderId}/transactions`](../api/list-order-transactions.md) 查這個訂單的所有交易。
3.  有 `charged` 或 `claimed`：補標為已付款。
4.  有 `charging`：繼續等待（超商代碼最多 48 小時、ATM 3 天）。
5.  全部是 `initiated` 或 `failed`：視為未付款。

每天也可以用[查詢交易列表](../api/list-transactions.md)做一次完整對帳，見[查詢與對帳](querying.md)。

## 測試

-   測試環境**會實際送出**付款通知，送到測試環境 CRM 設定的網址。
-   沒有測試事件 API。要測試接收端，可以建立一筆測試交易並付款，或用 cURL 自己送一則模擬的 body 到你的網址（因為沒有簽章，模擬的 body 和真的格式相同）。
