---
title: "查詢與對帳"
url: "https://developer.oen.tw/developers/querying/"
---

> 來源：https://developer.oen.tw/developers/querying/（自動產生，請勿手動修改）

# 查詢與對帳

## 三種查詢

| 想知道 | 用這支 | 備註 |
| --- | --- | --- |
| 某一筆交易的最新狀態 | [`GET /transactions/{id}`](../api/get-transaction.md) | 用 27 字元的 `id` 查，才會有 `productDetails` |
| 某個訂單的所有付款嘗試 | [`GET /order/{orderId}/transactions`](../api/list-order-transactions.md) | 只有 API 交易，含失敗與定期定額各期；一次回傳全部 |
| 一段期間的所有款項 | [`GET /transactions?start=&end=`](../api/list-transactions.md) | 每頁 50 筆，由新到舊；**包含非 API 的款項** |
| 定期定額的狀態 | [`GET /subscriptions/{id}`](../api/get-subscription.md) | 用 `S` 開頭的編號或內部 id |

## 交易列表的範圍

> 列表包含網域的所有款項
> 
> `GET /transactions` 列出的是整個網域的款項，除了 API 建立的交易，也包含應援商店訂單、捐款等其他收款，以及撥款後退款產生的負數調整款項。這些款項的 `id` 是 `C` 開頭。只要 API 交易時，請用 `orderId` 比對你的訂單，或篩選 `id` 為 `P` 開頭的項目。

### 期間與分頁

-   `start` 與 `end` 要一起帶，以台北時間的整天計算：`start` 當天 00:00 到 `end` 當天 23:59:59。
-   日期可以寫 `2026-09-01`，或 Unix **毫秒**時間戳。只帶一個或格式錯誤會回 500 `F0001`（`Invalid date`）。
-   依交易**建立時間**篩選，不是付款時間。
-   回應的 `page` 不是 `null` 時，把它原封不動放進下一次請求的 `?page=`，直到 `page` 是 `null`。

```js
async function listAll(start, end) {
  const all = [];
  let page = null;
  do {
    const qs = new URLSearchParams({ start, end, ...(page ? { page } : {}) });
    const res = await fetch(`https://payment-api.oen.tw/transactions?${qs}`, {
      headers: { Authorization: `Bearer ${process.env.OEN_API_TOKEN}` },
    });
    const result = await res.json();
    if (result.code !== "S0000") throw new Error(`${result.code} ${result.message}`);
    all.push(...result.data.transactions);
    page = result.data.page;
  } while (page);
  return all;
}
```

## 建議的對帳流程

1.  **每 15 分鐘**：處理還沒有結果的訂單（做法見[沒收到通知時](webhooks.md#%E6%B2%92%E6%94%B6%E5%88%B0%E9%80%9A%E7%9F%A5%E6%99%82)）。
2.  **每天**：用 `GET /transactions` 列出前一天建立的款項，只取 `P` 開頭的項目，和你的訂單逐筆比對：
    -   你的系統是「已付款」，應援是 `failed` 或 `initiated`：查明原因，不要出貨。
    -   應援是 `charged` 或 `claimed`，你的系統不是「已付款」：補標。
    -   同一個 `orderId` 有兩筆以上成功：[退款](refunds.md)多的那筆。
3.  **每次撥款後**：到 CRM「撥款列表」匯出撥款細項，核對手續費與撥款金額。見[查詢交易與對帳](https://developer.oen.tw/merchant/transactions/)。

## 查詢的注意事項

-   請不要高頻率地輪詢單筆交易。付款通知到了再查，或用上面的定期工作即可。
-   交易剛完成的極短時間內，查到的可能還是舊狀態，稍等幾秒再查。
-   用 `P` 開頭的交易編號查詢單筆時，回應不含 `productDetails` 與 `numberOfPeriods`。
-   回應裡沒有 `currency` 欄位，Payment API 的交易都是新台幣。
