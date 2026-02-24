#!/bin/bash
#
# OpenCode Dual Version Uninstall Script
# 移除雙版本設定，恢復單一版本
#

set -e

# ============================================
# 處理中斷信號 - 優雅退出不報錯
# ============================================
cleanup() {
    echo ""
    echo -e "${YELLOW}已取消卸載${NC}"
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

print_info() {
    echo -e "${BLUE}  ℹ $1${NC}"
}

# ============================================
# 安全讀取函數 - 處理中斷和空輸入
# ============================================
safe_read() {
    local prompt="$1"
    local default="$2"
    local var_name="$3"
    
    echo -en "${YELLOW}$prompt${NC}"
    read -r input || {
        eval "$var_name='$default'"
        echo ""
        return 0
    }
    
    if [ -z "$input" ]; then
        eval "$var_name='$default'"
    else
        eval "$var_name='$input'"
    fi
}

# ============================================
# 主程式
# ============================================
print_header "OpenCode Dual Version Uninstall"
echo ""
echo -e "${YELLOW}此腳本將移除雙版本設定${NC}"
echo ""

CONFIG_DIR="$HOME/.config/opencode"
BIN_DIR="$HOME/.local/bin"

# Step 1: 移除 Wrapper Scripts
print_step "移除 Wrapper Scripts..."

if [ -f "$BIN_DIR/opencode-full" ]; then
    rm -f "$BIN_DIR/opencode-full"
    print_success "已移除 opencode-full"
fi

if [ -f "$BIN_DIR/opencode-slim" ]; then
    rm -f "$BIN_DIR/opencode-slim"
    print_success "已移除 opencode-slim"
fi

# Step 2: 移除 Slim 配置
print_step "移除 Slim 配置..."

if [ -f "$CONFIG_DIR/oh-my-opencode-slim.json" ]; then
    safe_read "是否移除 oh-my-opencode-slim.json？(y/N): " "n" remove_slim
    if [[ "$remove_slim" =~ ^[Yy]$ ]]; then
        rm -f "$CONFIG_DIR/oh-my-opencode-slim.json"
        print_success "已移除 oh-my-opencode-slim.json"
    else
        print_info "保留 oh-my-opencode-slim.json"
    fi
else
    print_info "oh-my-opencode-slim.json 不存在"
fi

# Step 3: 移除 Full 備份
print_step "移除 Full 備份..."

if [ -f "$CONFIG_DIR/oh-my-opencode-full.json" ]; then
    safe_read "是否移除 oh-my-opencode-full.json 備份？(y/N): " "n" remove_backup
    if [[ "$remove_backup" =~ ^[Yy]$ ]]; then
        rm -f "$CONFIG_DIR/oh-my-opencode-full.json"
        print_success "已移除 oh-my-opencode-full.json"
    else
        print_info "保留 oh-my-opencode-full.json"
    fi
else
    print_info "oh-my-opencode-full.json 不存在"
fi

# Step 4: 恢復原始配置
print_step "恢復原始配置..."

safe_read "是否將 opencode.json 恢復為 Full 版？(Y/n): " "y" restore_full
if [[ ! "$restore_full" =~ ^[Nn]$ ]]; then
    if command -v jq &> /dev/null; then
        tmp_file=$(mktemp)
        jq '(.plugin // []) | map(select(startswith("oh-my-opencode") | not)) | . + ["oh-my-opencode"] | unique' "$CONFIG_DIR/opencode.json" > "$tmp_file"
        jq --slurpfile plugins "$tmp_file" '.plugin = $plugins[0]' "$CONFIG_DIR/opencode.json" > "${tmp_file}.2" && mv "${tmp_file}.2" "$CONFIG_DIR/opencode.json"
        rm -f "$tmp_file"
        print_success "已恢復為 oh-my-opencode (Full)"
    fi
else
    print_info "保持目前配置"
fi

# Step 5: 移除 PATH 設定 (可選)
print_step "檢查 PATH 設定..."

if [ -f "$HOME/.zshrc" ]; then
    if grep -q 'export PATH="\$HOME/.local/bin:\$PATH"' "$HOME/.zshrc" 2>/dev/null; then
        safe_read "是否從 ~/.zshrc 移除 PATH 設定？(y/N): " "n" remove_path
        if [[ "$remove_path" =~ ^[Yy]$ ]]; then
            cp "$HOME/.zshrc" "$HOME/.zshrc.backup.$(date +%Y%m%d%H%M%S)"
            sed -i '' '/# Added by opencode-dual-version setup/d' "$HOME/.zshrc"
            sed -i '' '/export PATH="\$HOME\/.local\/bin:\$PATH"/d' "$HOME/.zshrc"
            print_success "已從 ~/.zshrc 移除 PATH 設定"
            print_info "備份已保存為 ~/.zshrc.backup.*"
        fi
    fi
fi

# 完成
print_header "卸載完成！"
echo ""
echo -e "${GREEN}已移除:${NC}"
echo "  - Wrapper scripts (opencode-full, opencode-slim)"
echo ""
echo -e "${GREEN}你可以:${NC}"
echo "  - 繼續使用 opencode (目前為 Full 版)"
echo "  - 重新安裝雙版本: ./setup.sh"
echo ""
