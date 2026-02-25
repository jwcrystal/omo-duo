# omo-duo - Full & Slim 並行使用

讓你同時使用 [oh-my-opencode](https://github.com/samwang-design/oh-my-opencode) (Full) 和 [oh-my-opencode-slim](https://github.com/alvinunreal/oh-my-opencode-slim) (Slim) 兩個版本。

```bash
opencode-full  # 完整版 - 功能最完整，適合複雜專案
opencode-slim  # 精簡版 - 省更多 token，適合日常開發
```

## 特色

- ✅ 一鍵切換 Full / Slim 版本
- ✅ 保留所有共用 plugins（envsitter 等）
- ✅ 兩個版本的 agent 配置獨立，可各自調整模型
- ✅ 內建 opencode-notifier 支援（見 [官方文檔](https://github.com/Mohak34/opencode-notifier)）

## 前置需求

- [OpenCode](https://opencode.ai) 已安裝
- [Bun](https://bun.sh) 已安裝
- [jq](https://stedolan.github.io/jq/) 已安裝 (`brew install jq`)

## 快速安裝

```bash
# 克隆或下載此專案
git clone https://github.com/jwcrystal/omo-duo.git
cd omo-duo

# 執行安裝腳本
./setup.sh
```

## 手動安裝

### Step 1: 備份現有配置

```bash
cp ~/.config/opencode/oh-my-opencode.json ~/.config/opencode/oh-my-opencode-full.json
```

### Step 2: 安裝 Slim 版

```bash
bunx oh-my-opencode-slim@latest install --no-tui \
  --kimi=no --openai=no --anthropic=no --copilot=no \
  --zai-plan=yes --antigravity=no --chutes=no \
  --balanced-spend=no --tmux=no --skills=yes
```

> 💡 根據你的需求調整 provider 選項，詳見 [oh-my-opencode-slim 文檔](https://github.com/alvinunreal/oh-my-opencode-slim)

### Step 3: 創建 Wrapper Scripts

```bash
mkdir -p ~/.local/bin

# opencode-full
cat > ~/.local/bin/opencode-full << 'EOF'
#!/bin/bash
CONFIG_FILE="$HOME/.config/opencode/opencode.json"
if command -v jq &> /dev/null; then
    tmp_file=$(mktemp)
    jq '(.plugin // []) | map(select(startswith("oh-my-opencode") | not)) | . + ["oh-my-opencode"] | unique' "$CONFIG_FILE" > "$tmp_file"
    jq --slurpfile plugins "$tmp_file" '.plugin = $plugins[0]' "$CONFIG_FILE" > "${tmp_file}.2" && mv "${tmp_file}.2" "$CONFIG_FILE"
    rm -f "$tmp_file"
fi
echo "🔄 Switched to FULL version (oh-my-opencode)"
exec opencode "$@"
EOF
chmod +x ~/.local/bin/opencode-full

# opencode-slim
cat > ~/.local/bin/opencode-slim << 'EOF'
#!/bin/bash
CONFIG_FILE="$HOME/.config/opencode/opencode.json"
if command -v jq &> /dev/null; then
    tmp_file=$(mktemp)
    jq '(.plugin // []) | map(select(startswith("oh-my-opencode") | not)) | . + ["oh-my-opencode-slim"] | unique' "$CONFIG_FILE" > "$tmp_file"
    jq --slurpfile plugins "$tmp_file" '.plugin = $plugins[0]' "$CONFIG_FILE" > "${tmp_file}.2" && mv "${tmp_file}.2" "$CONFIG_FILE"
    rm -f "$tmp_file"
fi
echo "🔄 Switched to SLIM version (oh-my-opencode-slim)"
exec opencode "$@"
EOF
chmod +x ~/.local/bin/opencode-slim
```

### Step 4: 更新 PATH
根據你的 shell 選擇對應的設定檔：
```bash
# zsh (macOS 預設)
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
# bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### Step 5: 安裝 opencode-notifier (可選)

```bash
# 複製配置文件
cp opencode-notifier.json ~/.config/opencode/

# 添加 plugin
jq '(.plugin // []) | . + ["@mohak34/opencode-notifier"] | unique' \
  ~/.config/opencode/opencode.json > /tmp/opencode.json && \
  mv /tmp/opencode.json ~/.config/opencode/opencode.json
```

> 📖 完整配置說明請參考 [opencode-notifier 官方文檔](https://github.com/Mohak34/opencode-notifier)

## 使用方式

```bash
# 啟動 Full 版（完整功能）
opencode-full

# 啟動 Slim 版（省 token）
opencode-slim

# 直接使用 opencode（會使用上次設定的版本）
opencode
```

## 配置文件說明

| 檔案 | 說明 |
|------|------|
| `~/.config/opencode/opencode.json` | 主配置（plugin 會被 wrapper 切換） |
| `~/.config/opencode/oh-my-opencode.json` | Full 版 agent 配置 |
| `~/.config/opencode/oh-my-opencode-slim.json` | Slim 版 agent 配置 |
| `~/.config/opencode/opencode-notifier.json` | Notifier 通知配置 |
| `~/.config/opencode/skills/` | OpenCode Skills 目錄 |
| `~/.local/bin/opencode-full` | Full 版啟動腳本 |
| `~/.local/bin/opencode-slim` | Slim 版啟動腳本 |

## 共用 Plugins

以下 plugins 在兩個版本間保持不變，wrapper 只會切換 `oh-my-opencode*`：

- `envsitter-guard@latest` - 環境變數保護
- `@mohak34/opencode-notifier` - 系統通知

新增其他 plugin 後也會被保留。

## 自訂 Agent 模型

兩個版本的 agent 配置是獨立的，可以各自調整：

```bash
# 編輯 Full 版配置
vim ~/.config/opencode/oh-my-opencode.json

# 編輯 Slim 版配置
vim ~/.config/opencode/oh-my-opencode-slim.json
```

## 版本差異

| 項目 | Full 版 | Slim 版 |
|------|---------|---------|
| Token 消耗 | 較多 | 較少 |
| 功能完整度 | 最完整 | 精簡 |
| 適用場景 | 複雜專案、架構設計 | 日常開發、快速迭代 |

## 卸載

```bash
./uninstall.sh
```

或手動移除：

```bash
rm -f ~/.local/bin/opencode-full
rm -f ~/.local/bin/opencode-slim
rm -f ~/.config/opencode/oh-my-opencode-slim.json
rm -f ~/.config/opencode/oh-my-opencode-full.json
```

## 常見問題

### Q: 切換版本後還是載入了舊版本？

A: 確保使用 wrapper scripts (`opencode-full` / `opencode-slim`) 而不是直接執行 `opencode`。

### Q: 如何確認目前使用哪個版本？

```bash
cat ~/.config/opencode/opencode.json | jq '.plugin'
```

### Q: 如何更新 Full / Slim 版本？

```bash
# 直接更新，wrapper 不會鎖定版號
bunx oh-my-opencode@latest install    # 更新 Full
bunx oh-my-opencode-slim@latest install  # 更新 Slim
```

### Q: Skills 安裝在哪裡？

OpenCode 的 Skills 位於 `~/.config/opencode/skills/`，不是 `~/.agents/skills/`。

如果你使用 `npx skills install` 安裝 skills，它會安裝到 `~/.agents/skills/`，但 OpenCode 不會讀取該目錄。請使用 OpenCode 內建的 skills 機制。

### Q: 執行 opencode-full/opencode-slim 顯示 command not found？

這表示 PATH 設定尚未生效，請執行：

```bash
# zsh
source ~/.zshrc

# bash
source ~/.bashrc
```

或者開啟新的終端機視窗。

## 授權

MIT License
