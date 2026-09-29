---
title: "定期定額"
url: "https://developers.oentech.ai/developers/subscriptions/"
---

> 來源：https://developers.oentech.ai/developers/subscriptions/（自動產生，請勿手動修改）

# 定期定額

定期定額是「消費者同意一次，之後由應援依週期自動扣款」。只支援信用卡，扣款週期以月為單位。

## 三種建立方式

|  | [建立定期定額](../api/checkout-subscription.md) | [建立預約定期定額](../api/checkout-schedule.md) | [用 token 建立定期定額](../api/token-subscriptions.md) |
| --- | --- | --- | --- |
| 消費者要做的事 | 在結帳頁付第一期 | 在結帳頁綁卡（首期是今天時同時付款） | 不用，之前已經[綁卡](saved-cards.md) |
| 第一期何時扣 | 消費者付款當下 | `startDate`：今天就是付款當下，未來日期就在當天扣 | 不帶 `startDate` 就在呼叫 API 當下；帶未來日期就在當天扣 |
| 扣款間隔 | 固定每 1 個月 | 1 到 12 個月（`paymentInterval`） | 1 到 12 個月 |
| `startDate` | 不支援 | 今天到 12 個月內 | **必須晚於今天**，12 個月內 |
| 回應 | `id`、`transactionHid` | `id`、`subscriptionHid` | `subscriptionId`、`transactionId`、`authCode` |
| 適合 | 最簡單的月費 | 季繳、年繳、下個月才開始扣 | 已經有存卡的會員 |

-   `numberOfPeriods` 是總期數，最少 2 期；不帶就是不限期，直到取消。
-   每期金額固定，就是建立時的 `amount`。要改金額，請取消後重新建立。
-   定期定額編號是 `S` 開頭，查詢與取消都用它。用「建立定期定額」時，第一期付款成功後，付款通知與查詢結果的 `subscriptionId` 就是這個編號。

## 每期什麼時候扣款

-   應援每天**台北時間上午 9 點**執行扣款。
-   下一期日期 = 上一期實際扣款的日期 + 間隔月數。
-   每次扣款前 3 天，應援會寄扣款提醒信給消費者（有 Email 時）。
-   每一期的結果都會送出 `purpose` 為 `charge`、`action` 為 `subscription` 的[付款通知](../api/objects/webhook.md)。

> 日期會往前或往後移
> 
> -   起始日是 29、30、31 日時，遇到較短的月份會移到較早的日期，之後就維持在那一天。例如 1/31 起始，之後可能是 2/28、3/28。
> -   某一期扣款失敗、重扣成功後，之後各期會以重扣成功的日期往後推。
> 
> 如果你的系統需要固定在某一天扣款，請把起始日設在每月 28 日以前。以 [`GET /subscriptions/{id}`](../api/get-subscription.md) 的 `nextChargeAt` 為準。

## 扣款失敗

> 預設不重扣：一期失敗，整個定期定額就停止
> 
> 重扣機制**預設是關閉的**。某一期扣款失敗時，定期定額會變成 `error`，**之後所有期數都不會再扣款**，也不會自動恢復。

建議開啟重扣：CRM「總設定」→「開發者」→「定期交易重試機制（Beta）」→「定期購買」。開啟後：

-   失敗後最多重扣 **2 次**，每次間隔約 24 小時。
-   發卡銀行明確拒絕（例如卡片停用）或付款結果不明時，不會重扣。
-   重扣中的狀態是 `retryScheduled`；重扣成功就回到 `ongoing`，用完仍失敗就變成 `error`。
-   每一次重扣都會送付款通知，`isRetry` 為 `true`。

定期定額停止後，請聯絡消費者重新訂閱，例如換一張卡走一次[建立定期定額](../api/checkout-subscription.md)。

## 取消

呼叫 [`PUT /subscriptions/{subscriptionHid}`](../api/cancel-subscription.md)，或在 CRM「定期購買」按「終止定期購買」。

-   只接受 `S` 開頭的定期定額編號。
-   **請一定要送 body**（至少 `merchantId`），沒送會回 500。
-   可以取消的狀態：`scheduled`、`ongoing`、`retryScheduled`。
-   取消後不能恢復。

消費者提出取消，就應該立即取消，不需要等消費者再次確認；取消之後才扣到的款項，請退款給消費者。

## 查詢

-   單筆：[`GET /subscriptions/{id}`](../api/get-subscription.md)，可以用 `S` 編號或內部 id。
-   某一期的交易：付款通知裡的 `id`，或用[訂單編號查詢](../api/list-order-transactions.md)列出同一個 `orderId` 的所有期數。
-   狀態說明見 [Subscription 物件](../api/objects/subscription.md)。

> GET /subscriptions 不是查這裡的定期定額
> 
> [`GET /subscriptions`](../api/list-subscriptions.md)（不帶 id）列出的是應援商店的「定期購」訂單，不是用 Payment API 建立的定期定額。

## 3D 驗證與綁卡

-   `use3d: true` 時，消費者在結帳頁走 3D 驗證。應援可能依收單設定強制 3D。
-   部分收單機構不支援 0 元驗證，綁卡時會**先授權新台幣 1 元再立即退回**，結帳頁會事先告知消費者。
-   首期日在未來時，消費者在結帳頁只綁卡，卡片是否可用要到首期扣款時才知道。

## 消費者要換卡

Payment API 目前沒有公開的換卡流程。常見做法：取消舊的定期定額，請消費者重新走一次結帳建立新的。

## 付款通知

| 時機 | purpose |
| --- | --- |
| 「建立定期定額」第一期付款 | `charge`（`action: subscription`） |
| 「建立預約定期定額」結帳完成 | `schedule_subscription` |
| 之後每一期（含重扣） | `charge`（`action: subscription`） |
| 「用 token 建立定期定額」的第一期 | 不送，以 API 回應為準 |
| 取消、重扣排定或用完 | `subscription_cancelled`、`subscription_retry`，需請應援開啟 |

欄位見[付款通知內容](../api/objects/webhook.md)。
