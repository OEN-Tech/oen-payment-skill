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

# Oen Payment Skill — 應援金流 Claude Code 技能

> 讓 Claude Code 成為你的金流整合助手

這是一個 [Claude Code](https://docs.anthropic.com/en/docs/claude-code) 的 **Skill（技能）**，協助開發者快速整合 [Oen Payment（應援金流）](https://oen.tw) REST API。安裝後，Claude Code 會在你提及金流相關需求時自動啟用，提供 API 串接指引、程式碼生成、錯誤排查等服務。

## 功能特色

- **API 串接引導** — 逐步引導你完成付款頁面建立、定期定額、退款、交易查詢等操作
- **多語言程式碼生成** — 產生可直接使用的 TypeScript、JavaScript、Python 或 cURL 範例程式碼
- **錯誤排查** — 根據回應碼對照表快速診斷問題，提供解決建議
- **MCP Server 設定** — 引導設定 Oen Payment MCP Server，實現 AI 輔助的金流操作
- **完整 API 文件** — 內建所有 endpoint 的請求格式、回應格式、範例和測試卡號

## 支援的付款方式

| 付款方式 | 說明 |
|---------|------|
| 信用卡 | VISA、Mastercard、JCB |
| LINE Pay | 需另外申請開通 |
| 超商代碼 | 全家便利商店繳費 |
| 虛擬帳號 | ATM 轉帳 |
| Apple Pay | 行動支付 |
| Taiwan Pay | TWQR 掃碼支付 |

## 安裝方式

### 方法一：直接複製到你的 Claude Code 技能目錄

```bash
# 複製到全域技能目錄
cp -r oen-payment-skill ~/.claude/skills/oen-payment

# 或複製到專案級技能目錄
cp -r oen-payment-skill .claude/skills/oen-payment
```

### 方法二：透過 Git Clone

```bash
# Clone 到全域技能目錄
git clone https://github.com/OEN-Tech/oen-payment-skill.git ~/.claude/skills/oen-payment

# 或 Clone 到專案級技能目錄
git clone https://github.com/OEN-Tech/oen-payment-skill.git .claude/skills/oen-payment
```

安裝完成後，重新啟動 Claude Code 即可生效。

## 使用方式

安裝後，當你在 Claude Code 中提及以下關鍵字時，技能會自動觸發：

- `oen payment`、`應援金流`、`oen 金流`
- 付款、結帳、checkout
- 定期定額、subscription
- 退款、refund
- 交易查詢、transaction

### 範例對話

```
> 幫我用 TypeScript 串接 Oen Payment 建立一個結帳頁面

> 如何設定 Oen Payment 的 webhook？

> 退款時收到 T0001 錯誤碼是什麼意思？

> 幫我建立一個每月扣款 500 元的定期定額
```

## 搭配 MCP Server 使用

除了此技能外，你也可以安裝 [Oen Payment MCP Server](https://github.com/OEN-Tech/oen-payment-mcp-server) 來取得即時的金流操作能力（建立交易、查詢交易、退款等）。

### 快速設定

1. 設定 GitHub Packages 存取權限：

```bash
echo "@OEN-Tech:registry=https://npm.pkg.github.com" >> ~/.npmrc
echo "//npm.pkg.github.com/:_authToken=YOUR_GITHUB_TOKEN" >> ~/.npmrc
```

2. 在 Claude Code 的 MCP 設定中加入：

```json
{
  "mcpServers": {
    "oen-payment": {
      "command": "npx",
      "args": [
        "-y",
        "@OEN-Tech/oen-payment-mcp-server@latest",
        "--token=YOUR_API_TOKEN",
        "--merchantId=YOUR_MERCHANT_ID",
        "--env=testing"
      ]
    }
  }
}
```

3. 將 `YOUR_API_TOKEN` 替換為從應援 CRM 後台取得的 API Token，`YOUR_MERCHANT_ID` 替換為你的網域名稱。

## API 快速參考

### 主要 Endpoint

| 操作 | Method | Endpoint |
|------|--------|----------|
| 建立單次付款頁面 | POST | `/checkout` |
| 建立定期定額 | POST | `/checkout-subscription` |
| 建立排程定期定額 | POST | `/checkout-schedule` |
| 3D 驗證取得 Token | POST | `/checkout-token` |
| 查詢交易明細 | GET | `/transactions/:id` |
| 查詢交易列表 | GET | `/transactions` |
| 用訂單查詢交易 | GET | `/order/:orderId/transactions` |
| 查詢定期定額明細 | GET | `/subscriptions/:subscriptionId` |
| 取消定期定額 | PUT | `/subscriptions/:subscriptionId` |
| 退款 | POST | `/refunds/:transactionHid` |

### 環境

| 環境 | API 位址 | 結帳頁面 |
|------|---------|---------|
| 正式環境 | `https://payment-api.oen.tw` | `https://{merchantId}.oen.tw` |
| 測試環境 | `https://payment-api.testing.oen.tw` | `https://{merchantId}.testing.oen.tw` |

### 測試卡號

| 卡號 | 用途 |
|------|------|
| `4242 4242 4242 4242` | 成功交易 |
| `4000 0000 0000 2503` | 觸發 3D 驗證 |
| `5200 0000 0000 2151` | 觸發 3D 驗證 |
| `4012 8888 1888 8333` | 觸發失敗情境 |

> 測試提示：金額 > 100 為成功情境，金額 < 100 為失敗情境

### 系統回應代碼

| 代碼 | 說明 |
|------|------|
| S0000 | 執行成功 |
| A0001 | 未授權 |
| V0001 | 請求錯誤 |
| V0002 | 交易狀態錯誤 |
| T0001 | 交易失敗 |
| T0002 | 安全碼 CVV 錯誤 |
| T0003 | 卡片過期 |
| T0004 | 額度不足 |
| T0005 | 拒絕授權 |
| F0001 | 系統錯誤 |

## 檔案結構

```
oen-payment-skill/
├── SKILL.md              # 技能定義檔（Claude Code 讀取此檔）
├── references/
│   └── api-docs.md       # 完整 API 文件參考
├── README.md             # 本文件
└── LICENSE               # MIT 授權
```

## 相關資源

- [Oen 應援科技官網](https://oen.tw)
- [Oen Payment MCP Server](https://github.com/OEN-Tech/oen-payment-mcp-server)
- [Claude Code 文件](https://docs.anthropic.com/en/docs/claude-code)

## 授權

MIT License — 詳見 [LICENSE](./LICENSE)

---

Power by the Oen Team
