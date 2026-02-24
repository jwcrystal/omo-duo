#!/bin/bash
#
# OpenCode Dual Version Setup Script
# 同時安裝 oh-my-opencode (Full) 和 oh-my-opencode-slim (Slim)
#
# 使用方式: ./setup.sh [選項]
#
# 選項:
#   --skip-full     跳過 Full 版安裝（已安裝時使用）
#   --skip-slim     跳過 Slim 版安裝
#   --no-skills     不安裝 skills
#   --kimi=yes/no   啟用/停用 Kimi provider
#   --openai=yes/no 啟用/停用 OpenAI provider
#   --anthropic=yes/no 啟用/停用 Anthropic provider
#   --help          顯示幫助訊息
#

set -e

# ============================================
# 處理中斷信號 - 優雅退出不報錯
# ============================================
cleanup() {
    echo ""
    echo -e "${YELLOW}已取消安裝${NC}"
    exit 0
}
trap cleanup SIGINT SIGTERM

# ============================================
# 顏色定義
# ============================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ============================================
# 預設選項
# ============================================
SKIP_FULL=false
SKIP_SLIM=false
NO_SKILLS=false
KIMI=no
OPENAI=no
ANTHROPIC=no
COPILOT=no
ZAI_PLAN=yes
ANTIGRAVITY=no
CHUTES=no

# ============================================
# 安全讀取函數 - 處理中斷和空輸入
# ============================================
safe_read() {
    local prompt="$1"
    local default="$2"
    local var_name="$3"
    
    echo -en "${YELLOW}$prompt${NC}"
    read -r input || {
        # 中斷時返回預設值
        eval "$var_name='$default'"
        echo ""
        return 0
    }
    
    # 空輸入使用預設值
    if [ -z "$input" ]; then
        eval "$var_name='$default'"
    else
        eval "$var_name='$input'"
    fi
}

# ============================================
# 解析參數
# ============================================
for arg in "$@"; do
    case $arg in
        --skip-full) SKIP_FULL=true ;;
        --skip-slim) SKIP_SLIM=true ;;
        --no-skills) NO_SKILLS=true ;;
        --kimi=*) KIMI="${arg#*=}" ;;
        --openai=*) OPENAI="${arg#*=}" ;;
        --anthropic=*) ANTHROPIC="${arg#*=}" ;;
        --copilot=*) COPILOT="${arg#*=}" ;;
        --zai-plan=*) ZAI_PLAN="${arg#*=}" ;;
        --antigravity=*) ANTIGRAVITY="${arg#*=}" ;;
        --chutes=*) CHUTES="${arg#*=}" ;;
        --help)
            echo "OpenCode Dual Version Setup Script"
            echo ""
            echo "使用方式: ./setup.sh [選項]"
            echo ""
            echo "選項:"
            echo "  --skip-full       跳過 Full 版安裝"
            echo "  --skip-slim       跳過 Slim 版安裝"
            echo "  --no-skills       不安裝 skills"
            echo "  --kimi=yes/no     啟用 Kimi provider"
            echo "  --openai=yes/no   啟用 OpenAI provider"
            echo "  --anthropic=yes/no 啟用 Anthropic provider"
            echo "  --zai-plan=yes/no 啟用 ZAI Coding Plan provider"
            echo "  --antigravity=yes/no 啟用 Antigravity provider"
            echo "  --chutes=yes/no   啟用 Chutes provider"
            echo "  --help            顯示此幫助訊息"
            exit 0
            ;;
        *)
            echo -e "${RED}未知參數: $arg${NC}"
            exit 1
            ;;
    esac
done

# ============================================
# 輔助函數
# ============================================
print_header() {
    echo ""
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}  $1"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
}

print_step() {
    echo ""
    echo -e "${YELLOW}▶ $1${NC}"
}

print_success() {
    echo -e "${GREEN}  ✓ $1${NC}"
}

print_error() {
    echo -e "${RED}  ✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}  ℹ $1${NC}"
}

# ============================================
# 主程式
# ============================================
print_header "OpenCode Dual Version Setup"
echo ""

# Step 0: 檢查前置需求
print_step "檢查前置需求..."

# 檢查 jq
if ! command -v jq &> /dev/null; then
    print_error "jq 未安裝"
    echo ""
    echo "  請執行: brew install jq"
    exit 1
fi
print_success "jq 已安裝"

# 檢查 bun
if ! command -v bun &> /dev/null; then
    print_error "bun 未安裝"
    echo ""
    echo "  請執行: curl -fsSL https://bun.sh/install | bash"
    exit 1
fi
print_success "bun 已安裝"

# 檢查 opencode
if ! command -v opencode &> /dev/null; then
    print_error "opencode 未安裝"
    echo ""
    echo "  請先安裝 OpenCode: https://opencode.ai"
    exit 1
fi
OPENCODE_VERSION=$(opencode --version 2>&1 | head -1)
print_success "opencode 已安裝 ($OPENCODE_VERSION)"

# Step 1: 備份現有配置
print_step "備份現有配置..."

CONFIG_DIR="$HOME/.config/opencode"
mkdir -p "$CONFIG_DIR"

if [ -f "$CONFIG_DIR/oh-my-opencode.json" ]; then
    cp "$CONFIG_DIR/oh-my-opencode.json" "$CONFIG_DIR/oh-my-opencode-full.json"
    print_success "已備份 oh-my-opencode.json → oh-my-opencode-full.json"
else
    print_info "oh-my-opencode.json 不存在，將在安裝 full 版時建立"
fi

# Step 2: 安裝 Full 版
if [ "$SKIP_FULL" = false ]; then
    print_step "安裝 oh-my-opencode (Full 版)..."
    
    print_info "這將覆蓋現有的 oh-my-opencode 配置"
    safe_read "確定要繼續嗎？(y/N): " "n" confirm_full
    if [[ "$confirm_full" =~ ^[Yy]$ ]]; then
        bunx oh-my-opencode@latest install 2>&1 || {
            print_error "Full 版安裝失敗"
            print_info "你可以稍後手動執行: bunx oh-my-opencode@latest install"
        }
        print_success "Full 版安裝完成"
        
        # 再次備份
        if [ -f "$CONFIG_DIR/oh-my-opencode.json" ]; then
            cp "$CONFIG_DIR/oh-my-opencode.json" "$CONFIG_DIR/oh-my-opencode-full.json"
            print_success "已更新 oh-my-opencode-full.json"
        fi
    else
        print_info "跳過 Full 版安裝"
    fi
else
    print_info "跳過 Full 版安裝 (--skip-full)"
fi

# Step 3: 安裝 Slim 版
if [ "$SKIP_SLIM" = false ]; then
    print_step "安裝 oh-my-opencode-slim (Slim 版)..."
    
    SKILLS_FLAG="yes"
    if [ "$NO_SKILLS" = true ]; then
        SKILLS_FLAG="no"
    fi
    
    print_info "Provider 設定:"
    echo "    Kimi: $KIMI"
    echo "    OpenAI: $OPENAI"
    echo "    Anthropic: $ANTHROPIC"
    echo "    Copilot: $COPILOT"
    echo "    ZAI Plan: $ZAI_PLAN"
    echo "    Antigravity: $ANTIGRAVITY"
    echo "    Chutes: $CHUTES"
    echo "    Skills: $SKILLS_FLAG"
    
    bunx oh-my-opencode-slim@latest install --no-tui \
        --kimi="$KIMI" \
        --openai="$OPENAI" \
        --anthropic="$ANTHROPIC" \
        --copilot="$COPILOT" \
        --zai-plan="$ZAI_PLAN" \
        --antigravity="$ANTIGRAVITY" \
        --chutes="$CHUTES" \
        --balanced-spend=no \
        --tmux=no \
        --skills="$SKILLS_FLAG" 2>&1 || {
        print_error "Slim 版安裝失敗"
        print_info "你可以稍後手動執行安裝指令"
    }
    print_success "Slim 版安裝完成"
else
    print_info "跳過 Slim 版安裝 (--skip-slim)"
fi

# Step 4: 創建 Wrapper Scripts
print_step "創建 Wrapper Scripts..."

BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"

# opencode-full
cat > "$BIN_DIR/opencode-full" << 'WRAPPER'
#!/bin/bash
# Switch to full version - only replace oh-my-opencode* plugin, keep others
CONFIG_FILE="$HOME/.config/opencode/opencode.json"

if command -v jq &> /dev/null; then
    tmp_file=$(mktemp)
    jq '(.plugin // []) | map(select(startswith("oh-my-opencode") | not)) | . + ["oh-my-opencode"] | unique' "$CONFIG_FILE" > "$tmp_file"
    jq --slurpfile plugins "$tmp_file" '.plugin = $plugins[0]' "$CONFIG_FILE" > "${tmp_file}.2" && mv "${tmp_file}.2" "$CONFIG_FILE"
    rm -f "$tmp_file"
else
    echo "Error: jq is required. Install with: brew install jq"
    exit 1
fi

echo "🔄 Switched to FULL version (oh-my-opencode)"
exec opencode "$@"
WRAPPER
chmod +x "$BIN_DIR/opencode-full"
print_success "已創建 opencode-full"

# opencode-slim
cat > "$BIN_DIR/opencode-slim" << 'WRAPPER'
#!/bin/bash
# Switch to slim version - only replace oh-my-opencode* plugin, keep others
CONFIG_FILE="$HOME/.config/opencode/opencode.json"

if command -v jq &> /dev/null; then
    tmp_file=$(mktemp)
    jq '(.plugin // []) | map(select(startswith("oh-my-opencode") | not)) | . + ["oh-my-opencode-slim"] | unique' "$CONFIG_FILE" > "$tmp_file"
    jq --slurpfile plugins "$tmp_file" '.plugin = $plugins[0]' "$CONFIG_FILE" > "${tmp_file}.2" && mv "${tmp_file}.2" "$CONFIG_FILE"
    rm -f "$tmp_file"
else
    echo "Error: jq is required. Install with: brew install jq"
    exit 1
fi

echo "🔄 Switched to SLIM version (oh-my-opencode-slim)"
exec opencode "$@"
WRAPPER
chmod +x "$BIN_DIR/opencode-slim"
print_success "已創建 opencode-slim"

# Step 5: 更新 PATH
print_step "檢查 PATH 設定..."

if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    # 檢測 shell
    SHELL_RC=""
    if [ -n "$ZSH_VERSION" ]; then
        SHELL_RC="$HOME/.zshrc"
    elif [ -n "$BASH_VERSION" ]; then
        SHELL_RC="$HOME/.bashrc"
    fi
    
    if [ -n "$SHELL_RC" ]; then
        echo "" >> "$SHELL_RC"
        echo "# Added by opencode-dual-version setup" >> "$SHELL_RC"
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$SHELL_RC"
        print_success "已將 ~/.local/bin 加入 $SHELL_RC"
        print_info "請執行: source $SHELL_RC"
    fi
else
    print_success "~/.local/bin 已在 PATH 中"
fi

# Step 6: 安裝 opencode-notifier
print_step "安裝 opencode-notifier..."

safe_read "是否安裝 @mohak34/opencode-notifier？(Y/n): " "y" install_notifier
if [[ ! "$install_notifier" =~ ^[Nn]$ ]]; then
    # 添加 plugin 到 opencode.json
    if command -v jq &> /dev/null; then
        tmp_file=$(mktemp)
        jq '(.plugin // []) | . + ["@mohak34/opencode-notifier"] | unique' "$CONFIG_DIR/opencode.json" > "$tmp_file"
        jq --slurpfile plugins "$tmp_file" '.plugin = $plugins[0]' "$CONFIG_DIR/opencode.json" > "${tmp_file}.2" && mv "${tmp_file}.2" "$CONFIG_DIR/opencode.json"
        rm -f "$tmp_file"
        print_success "已安裝 @mohak34/opencode-notifier plugin"
    fi
    
    # 複製 notifier 配置（如果腳本同目錄有 opencode-notifier.json）
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [ -f "$SCRIPT_DIR/opencode-notifier.json" ]; then
        cp "$SCRIPT_DIR/opencode-notifier.json" "$CONFIG_DIR/opencode-notifier.json"
        print_success "已複製 opencode-notifier.json 配置"
    else
        print_info "使用 notifier 預設配置"
    fi
else
    print_info "跳過 notifier 安裝"
fi

# 完成
print_header "安裝完成！"
echo ""
echo -e "${GREEN}使用方式:${NC}"
echo ""
echo "  opencode-full  → 啟動 Full 版 (oh-my-opencode)"
echo "  opencode-slim  → 啟動 Slim 版 (oh-my-opencode-slim)"
echo "  opencode       → 使用上次設定的版本"
echo ""
echo -e "${GREEN}配置文件:${NC}"
echo ""
echo "  Full:  ~/.config/opencode/oh-my-opencode.json"
echo "  Slim:  ~/.config/opencode/oh-my-opencode-slim.json"
echo ""
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    echo -e "${YELLOW}⚠ 請執行以下指令使 PATH 生效:${NC}"
    echo ""
    echo "  source ~/.zshrc"
    echo ""
fi
