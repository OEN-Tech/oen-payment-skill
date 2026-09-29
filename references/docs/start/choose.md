---
title: "我該用哪一種收款方式？"
url: "https://developers.oentech.ai/start/choose/"
---

> 來源：https://developers.oentech.ai/start/choose/（自動產生，請勿手動修改）

# 我該用哪一種收款方式？

先用問答找到方向，再用下方的比較表確認細節。

## Payment API 的三種收款流程

大多數商家用 Payment API 就夠了。它有三種流程，差別在「誰決定什麼時候扣款」：

|  | 單次付款 | 定期定額 | 存卡與後續扣款 |
| --- | --- | --- | --- |
| 適合 | 購物、捐款、活動報名 | 會員月費、定期捐款 | 儲值、隨用隨扣、快速結帳 |
| 消費者要做的事 | 在結帳頁付款 | 在結帳頁綁卡並同意扣款 | 在綁卡頁完成 3D 驗證 |
| 之後誰扣款 | 不再扣款 | 應援依週期自動扣款 | 你的伺服器呼叫 API 扣款 |
| 金額 | 每次建立時決定 | 固定 | 每次扣款時決定 |
| 開始 | [單次付款](../developers/one-time.md) | [定期定額](../developers/subscriptions.md) | [存卡與後續扣款](../developers/saved-cards.md) |

## 各種方式比較

表格可以左右滑動。

|  | Payment API | WooCommerce 外掛 | Embed 嵌入式付款 | Subscription API |
| --- | --- | --- | --- | --- |
| 狀態 | 可直接使用 | 需開通 | 需開通 | 需開通 |
| 適合 | 自己的網站或 App | WordPress 商家 | 付款欄位嵌在自己頁面 | 需要試用期、方案變更等訂閱管理 |
| 要寫程式嗎 | 要 | 不用 | 要（前端與後端） | 要 |
| 付款畫面 | 應援結帳頁 | 應援結帳頁 | 你的頁面 | 見產品頁 |
| 驗證 | CRM 產生的 token | 外掛設定頁填入金鑰 | `pk_` 與 `sk_` 金鑰 | `sub_sk_` 金鑰 |
| 付款通知 | 沒有簽章，收到後回查 | 外掛自動處理 | 有簽章 | 有簽章 |
| 說明 | [快速開始](../developers/quickstart.md) | [安裝與設定](https://developers.oentech.ai/merchant/woocommerce/) | [Embed](../products/embed.md) | [Subscription API](../products/subscription-api.md) |

## 已經在用 Payment API？

Payment API 是應援主要支援的串接方式，會持續維護並加入新功能。這一版文件依正式環境 v10.3.1.1 更新，差異見[更新紀錄](https://developers.oentech.ai/changelog/)。
