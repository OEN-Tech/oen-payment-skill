---
title: "驗證與 token"
url: "https://developer.oen.tw/developers/authentication/"
---

> 來源：https://developer.oen.tw/developers/authentication/（自動產生，請勿手動修改）

# 驗證與 token

Payment API 用 CRM 產生的 token 驗證。每個網域在每個環境同時只有一把有效的 token。

## 產生 token

1.  確認網域已開啟 API 串接（開發者模式）。沒開時 CRM 不會出現「開發者」分頁，請商家聯絡應援。
2.  進入 CRM「總設定」→「開發者」分頁 →「應援金流設定」→「存取 Token」，按「產生 Token」。
3.  立刻複製保存。離開頁面後就看不到完整的 token。

需要後台管理員，或「金流串接管理員」角色。詳細步驟見[交給工程師串接前的準備](https://developer.oen.tw/merchant/api-access/)。

## 帶上 token

```http
Authorization: Bearer <token>
```

-   `Bearer` 要照這個大小寫，中間只有一個空白。
-   有 body 的請求要帶 `merchantId`，而且必須是 token 所屬的網域，否則回 400 `V0001`。查詢類的 GET 請求不需要帶，網域由 token 決定。

## token 的特性

| 特性 | 說明 |
| --- | --- |
| 有效期限 | **沒有期限**，直到重新產生 |
| 重新產生 | 舊 token **立刻失效**，沒有緩衝期 |
| 環境 | 測試與正式各自產生，不能互用 |
| 數量 | 每個網域、每個環境同時只有一把 |
| 放在哪裡 | 只放伺服器。API 不接受瀏覽器跨網域請求，也不要放進前端或 App |

> 更換 token 會中斷服務
> 
> 重新產生後，舊 token 立刻失效，CRM 也沒有確認視窗。要更換時，請事先安排：
> 
> 1.  準備好能立即更新 token 的部署方式。
> 2.  在離峰時間產生新 token。
> 3.  立刻部署，並確認 API 呼叫恢復正常。

## token 外洩時

1.  立刻到 CRM 重新產生，讓外洩的 token 失效。
2.  更新伺服器設定。
3.  用[查詢交易列表](../api/list-transactions.md)檢查外洩期間有沒有異常的建立或退款。

請不要把 token 貼到 email、聊天工具、AI 助手或公開的程式碼庫。

## 收到 401 A0001

| 可能原因 | 怎麼確認 |
| --- | --- |
| token 被重新產生過 | 問商家最近有沒有按過「重新產生 Token」 |
| 用錯環境 | 測試環境的 token 打到正式環境，或反過來 |
| header 格式錯誤 | 確認是 `Authorization: Bearer <token>`，沒有多餘空白或換行 |
| 網域的 API 串接被關閉 | 請商家聯絡應援 |

正式環境收到的是 **403**（沒有 `code` 欄位）時，原因是 IP 還沒綁定，不是 token 的問題，見[固定 IP 白名單](ip-allowlist.md)。
