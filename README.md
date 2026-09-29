```
  ___               ____                                  _
 / _ \  ___ _ __   |  _ \ __ _ _   _ _ __ ___   ___ _ __ | |_
| | | |/ _ \ '_ \  | |_) / _` | | | | '_ ` _ \ / _ \ '_ \| __|
| |_| |  __/ | | | |  __/ (_| | |_| | | | | | |  __/ | | | |_
 \___/ \___|_| |_| |_|   \__,_|\__, |_| |_| |_|\___|_| |_|\__|
                               |___/
 ____  _    _ _ _
/ ___|| | _(_) | |
\___ \| |/ / | | |
 ___) |   <| | | |
|____/|_|\_\_|_|_|
```

# Oen Payment Skill — 應援金流 AI 技能

這是一份給 AI 開發工具讀的技能檔（Skill），協助開發者串接[應援科技](https://oen.tw)的 Payment API（應援金流）。安裝後，你在 AI 工具裡提到應援金流、結帳、定期定額、退款、付款通知等需求時，AI 會自動載入串接規則與最新文件，幫你產生程式、解釋錯誤碼、檢查常見錯誤。

- 內容依正式環境 v10.3.1.1 查核，文件取自[應援開發者文件站](https://developer.oen.tw)。
- Skill 與文件站不同時，以文件站為準。

## 包含什麼

| 檔案 | 內容 |
| --- | --- |
| `SKILL.md` | AI 載入的主檔：什麼時候用、哪個任務讀哪一頁、AI 最常寫錯的規則（每條附出處）、安全提醒、不涵蓋的範圍 |
| `references/docs/` | 從文件站原樣匯出的頁面：API 參考（`api/`）、串接指南（`developers/`）、入門與常見問題（`start/`）、需開通的產品（`products/`） |
| `references/docs/manifest.json` | 匯出時間與文件站的 `sourceCommit`，用來確認內容是哪一版 |
| `scripts/sync-docs.sh` | 用新匯出的文件更新 `references/docs/` |
| `evals/` | 測試這個 Skill 的情境題與觸發題 |

## 安裝

### Claude Code

```bash
# 所有專案都能用
git clone https://github.com/OEN-Tech/oen-payment-skill.git ~/.claude/skills/oen-payment

# 或只給目前的專案用
git clone https://github.com/OEN-Tech/oen-payment-skill.git .claude/skills/oen-payment
```

安裝後重新啟動 Claude Code。之後要更新，到安裝的目錄執行 `git pull`。

### 其他支援 SKILL.md 的工具

把整個 repo 複製到該工具的技能目錄即可，例如 OpenClaw 是 `~/.openclaw/skills/oen-payment`。`SKILL.md` 會用相對路徑讀 `references/docs/`，請保留目錄結構。

## 使用方式

在對話中提到應援金流或 Payment API 的需求，Skill 就會載入。觸發詞包含：

- `oen payment`、`應援金流`、`應援 API`、`payment-api.oen.tw`
- 在應援的情境下提到結帳（checkout）、定期定額（subscription）、退款（refund）、付款通知（webhook）、存卡、token 扣款、對帳
- 錯誤碼與導回參數，例如 `payment_error`、`C026`

### 範例

```
> 幫我用 TypeScript 串接應援金流，建立單次付款的結帳頁

> 寫一個 Express 的付款通知接收端，收到後回查交易再更新訂單

> 幫我建立每月 299 元、共 12 期的定期定額，用 Python

> 已繳費的超商代碼訂單要怎麼用 API 退款？

> 用 token 扣款收到 409 C026，可以直接重試嗎？

> 測試環境都正常，上正式環境就回 403，是哪裡設定錯了？
```

## 涵蓋範圍

- Payment API 的 13 支公開端點：建立單次付款、定期定額、預約定期定額、綁卡頁、用 token 扣款與建立定期定額、查詢交易與定期定額、退款、取消定期定額。
- 付款方式：信用卡、Apple Pay、超商代碼、ATM 虛擬帳號、LINE Pay（超商代碼、ATM、LINE Pay 要先請應援開通）。
- 付款通知的接收與回查、漏掉通知時的補救、每日對帳。
- 錯誤碼、哪些錯誤可以重試、付款結果不明時的處理。
- 測試環境、正式環境的固定 IP 白名單、上線檢查清單。

## 不涵蓋

- **文件站沒有列出的端點或產品**：Skill 只涵蓋 `references/docs/api/` 列出的公開端點，其他需求請聯絡應援業務或客服。需要傳送完整卡號的 API 要符合 PCI DSS，不在文件站公開。
- **Embed 嵌入式付款、Subscription API、WooCommerce 外掛**：要先請應援開通。Skill 只附上文件站的說明頁，預設以 Payment API 回答。
- **Payment MCP**：目前是應援內部預覽版，尚未對外開放，見[文件站說明](https://developer.oen.tw/ai/mcp/)。
- **測試卡號**：各網域的測試環境收單設定不同，請向應援的聯絡人索取。
- **手續費與費率**：請到 CRM 查看，或詢問應援業務。

## 環境

| 環境 | API | 結帳頁 |
| --- | --- | --- |
| 測試 | `https://payment-api.testing.oen.tw` | `https://{網域名稱}.testing.oen.tw` |
| 正式 | `https://payment-api.oen.tw` | `https://{網域名稱}.oen.tw` |

- token 在各環境的 CRM 產生，兩個環境不能互用。
- 正式環境只接受已綁定的固定 IP，沒綁定會回 HTTP 403；測試環境沒有這個限制。上線前請先申請，見 `references/docs/developers/ip-allowlist.md`。

## 安全提醒

- Skill 只提供知識，實際呼叫 API 仍需要 CRM 產生的 token。
- token 只放在伺服器的環境變數（例如 `OEN_API_TOKEN`），不要貼進 AI 對話、前端程式或版本控制。已經外流時，請到 CRM 重新產生，舊的會立刻失效。

## 更新 references

`references/docs/` 是文件站匯出工具產生的內容，**請不要手動修改**。內容有誤時，請修正文件站，再重新匯出並同步：

```bash
scripts/sync-docs.sh <bundle-dir>
```

- `<bundle-dir>` 由應援的維護者用文件站的匯出工具產生；一般使用者只要在安裝目錄執行 `git pull` 就能取得更新，不需要自己執行這支腳本。
- bundle 裡要有 `manifest.json`、`INDEX.md` 與各章節目錄。腳本會用 bundle 的 `api/`、`developers/`、`start/`、`products/`、`INDEX.md`、`manifest.json` 取代 `references/docs/`，並印出 `sourceCommit`、`generatedAt`。
- 介紹 Skill 與 MCP 本身的 `ai/` 不複製；`INDEX.md` 會刪掉章節是 `ai` 的列，`manifest.json` 的 `pages` 只留下實際複製的頁面，其他內容原樣保留。
- 腳本需要 `python3`。它會先確認自己位在這個 Skill 的目錄，換上新內容時先把舊目錄移開，成功後才刪除；最後檢查 `manifest.json` 與 `INDEX.md` 列出的檔案都存在、頁面之間的相對連結都指得到檔案，有問題只列出警告。
- 同步後用 `git diff references/docs` 檢查變更，再一起提交。

## 維護：文件站網址

文件站的網域是 `developer.oen.tw`。網域變更時，除了重新匯出 `references/docs/`，也要修改手寫檔案中的網址：`SKILL.md`（description 的觸發詞、〈不涵蓋〉的 Payment MCP 出處、〈文件站〉）、`README.md`（開頭說明、〈不涵蓋〉的 Payment MCP 連結、〈相關資源〉）、`evals/evals.json`（情境 9）、`evals/trigger_eval.json`（1 題觸發題）。

## 檔案結構

```
oen-payment-skill/
├── SKILL.md                  # AI 載入的主檔
├── references/
│   └── docs/                 # 文件站匯出的頁面（自動產生，請勿手動修改）
│       ├── INDEX.md          # 頁面索引與網址
│       ├── manifest.json     # 匯出時間與 sourceCommit
│       ├── api/              # API 參考、錯誤碼、物件欄位
│       ├── developers/       # 串接指南
│       ├── start/            # 產品選擇、常見問題、名詞對照
│       └── products/         # Embed、Subscription API（需開通）
├── scripts/
│   └── sync-docs.sh          # 同步 references/docs/
├── evals/
│   ├── evals.json            # 情境題與評分標準
│   └── trigger_eval.json     # 觸發與不觸發的提問
├── README.md
└── LICENSE
```

## 相關資源

- [應援開發者文件站](https://developer.oen.tw)
- [全站純文字版（給 AI 讀）](https://developer.oen.tw/llms-full.txt)
- [應援科技官網](https://oen.tw)

## 授權

MIT License，詳見 [LICENSE](./LICENSE)。

---

Powered by the Oen Team
