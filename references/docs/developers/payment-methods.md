---
title: "付款方式"
url: "https://developers.oentech.ai/developers/payment-methods/"
---

> 來源：https://developers.oentech.ai/developers/payment-methods/（自動產生，請勿手動修改）

# 付款方式

## 支援的付款方式

| 付款方式 | `allowedPaymentMethods` 的值 | 開通 | 金額範圍（新台幣） | 付款期限 |
| --- | --- | --- | --- | --- |
| 信用卡 | `card`（一定會出現） | 隨金流開通 | 1 以上；200,000 以上要另外開通高額交易 | — |
| Apple Pay | 不用指定，自動出現 | 隨信用卡 | 同信用卡 | — |
| 超商代碼 | `cvs` | 請應援開通 | 80 到 20,000 | 取號後 48 小時 |
| ATM 虛擬帳號 | `atm` | 請應援開通（需要藍新金流） | 100 到 20,000 | 3 天 |
| LINE Pay | `linePay` | 自備 LINE Pay 商店帳號，請應援開通後在 CRM 設定 | 30 到 200,000 | 20 分鐘 |

-   不支援 Google Pay、信用卡分期。
-   幣別只支援新台幣。
-   金額不在範圍內的付款方式，結帳頁不會顯示。
-   超商代碼可以繳費的超商依網域設定而定：全家，或 7-ELEVEN、全家、OK、萊爾富。
-   只有[單次付款](../api/checkout.md)可以選擇付款方式。定期定額與存卡只支援信用卡。

## allowedPaymentMethods 的實際效果

> 這是「加開」，不是「只開」
> 
> 信用卡一定會出現在結帳頁，目前沒辦法只開超商代碼或只開 LINE Pay。

| 你傳入 | 結帳頁會出現 |
| --- | --- |
| 不傳，或 `[]` | 信用卡（＋ Apple Pay） |
| `["cvs"]` | 信用卡、超商代碼（＋ Apple Pay） |
| `["linePay"]` | 信用卡、LINE Pay（＋ Apple Pay） |
| `["atm"]` | 信用卡、ATM（＋ Apple Pay）。網域沒有設定藍新 ATM 時，ATM 不會出現 |
| `["cvs", "linePay"]` | 信用卡、超商代碼、LINE Pay（＋ Apple Pay） |

-   Apple Pay 只在支援的裝置與瀏覽器（例如 iPhone 的 Safari）顯示。
-   帶 `linePay` 但網域的 LINE Pay 還沒開通時，建立結帳會直接回 400 `V0001`（`LINE_PAY_NOT_ACTIVE`）。
-   帶 `cvs` 但網域沒有開通超商代碼時，建立結帳會成功，但消費者選超商時會失敗。請先確認開通狀態。
-   從 v10.3.0 起，結帳頁會照你傳入的清單顯示並把關。

## 各付款方式的流程差異

### 信用卡、Apple Pay

消費者當場付款，成功後立刻導回 `successUrl`，付款通知的 `status` 是 `charged` 或 `claimed`。

### 超商代碼、ATM

> 警告
> 
> 這兩種方式會收到**兩則**付款通知，而且 `id` 相同：
> 
> 1.  取號時：`status: charging`，沒有 `success` 欄位，`paymentInfo` 裡有繳費代碼或虛擬帳號。
> 2.  繳費後：`status: charged`、`success: true`；逾期未繳則是 `status: failed`、`message: PAYMENT_EXPIRED`。
> 
> 收到第一則時不要出貨。

-   取號後，消費者停在應援的繳費資訊頁，按「返回網站」才回到 `successUrl`。建議你也在訂單頁顯示繳費代碼與期限（取自付款通知的 `paymentInfo`）。
-   退款要帶消費者的銀行帳戶，由應援匯款，見[退款](refunds.md)。尚未繳費的超商代碼可以用退款 API 直接取消。

### LINE Pay

-   消費者被導到 LINE Pay 付款，確認前會先收到 `status: charging` 的通知，確認後再收到最終結果。
-   20 分鐘內沒有完成，交易會變成失敗（`PAYMENT_EXPIRED`）。
-   付款失敗或取消時導回 `failureUrl`，不帶 `payment_error`。
-   LINE Pay 的款項由 LINE Pay 直接撥給商家，付款成功的狀態是 `claimed`。

## 商家要先開通

各付款方式的開通方式，請把[開通金流與付款方式](https://developers.oentech.ai/merchant/activate/)轉給商家。
