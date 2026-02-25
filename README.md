# omo-duo - Switch between Full & Slim versions

A lightweight tool to switch between [oh-my-opencode](https://github.com/samwang-design/oh-my-opencode) (Full) and [oh-my-opencode-slim](https://github.com/alvinunreal/oh-my-opencode-slim) (Slim) versions.

[繁體中文](README.zh-TW.md)

```bash
opencode-full  # Full version - complete features, for complex projects
opencode-slim  # Slim version - saves tokens, for daily development
```

## Features

- ✅ One-command switch between Full / Slim versions
- ✅ Preserves shared plugins (envsitter, etc.)
- ✅ Independent agent configs for each version
- ✅ opencode-notifier support ([docs](https://github.com/Mohak34/opencode-notifier))

## Requirements

- [OpenCode](https://opencode.ai) installed
- [Bun](https://bun.sh) installed
- [jq](https://stedolan.github.io/jq/) installed (`brew install jq`)

## Quick Install

```bash
# Clone this repository
git clone https://github.com/jwcrystal/omo-duo.git
cd omo-duo

# Run setup script
./setup.sh
```

## Manual Install

### Step 1: Backup existing config

```bash
cp ~/.config/opencode/oh-my-opencode.json ~/.config/opencode/oh-my-opencode-full.json
```

### Step 2: Install Slim version

```bash
bunx oh-my-opencode-slim@latest install --no-tui \
  --kimi=no --openai=no --anthropic=no --copilot=no \
  --zai-plan=yes --antigravity=no --chutes=no \
  --balanced-spend=no --tmux=no --skills=yes
```

> 💡 Adjust provider options based on your needs. See [oh-my-opencode-slim docs](https://github.com/alvinunreal/oh-my-opencode-slim)

### Step 3: Create Wrapper Scripts

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

### Step 4: Update PATH

```bash
# zsh (macOS default)
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### Step 5: Install opencode-notifier (Optional)

```bash
# Copy config file
cp opencode-notifier.json ~/.config/opencode/

# Add plugin
jq '(.plugin // []) | . + ["@mohak34/opencode-notifier"] | unique' \
  ~/.config/opencode/opencode.json > /tmp/opencode.json && \
  mv /tmp/opencode.json ~/.config/opencode/opencode.json
```

> 📖 See [opencode-notifier docs](https://github.com/Mohak34/opencode-notifier) for full configuration

## Usage

```bash
# Start Full version (complete features)
opencode-full

# Start Slim version (saves tokens)
opencode-slim

# Use opencode directly (uses last set version)
opencode
```

## Config Files

| File | Description |
|------|-------------|
| `~/.config/opencode/opencode.json` | Main config (plugin switched by wrapper) |
| `~/.config/opencode/oh-my-opencode.json` | Full version agent config |
| `~/.config/opencode/oh-my-opencode-slim.json` | Slim version agent config |
| `~/.config/opencode/opencode-notifier.json` | Notifier config |
| `~/.config/opencode/skills/` | OpenCode Skills directory |
| `~/.local/bin/opencode-full` | Full version wrapper script |
| `~/.local/bin/opencode-slim` | Slim version wrapper script |

## Shared Plugins

These plugins remain unchanged between versions, wrapper only switches `oh-my-opencode*`:

- `envsitter-guard@latest` - Environment variable protection
- `@mohak34/opencode-notifier` - System notifications

Other plugins you add will also be preserved.

## Customize Agent Models

Each version has independent agent configs:

```bash
# Edit Full version config
vim ~/.config/opencode/oh-my-opencode.json

# Edit Slim version config
vim ~/.config/opencode/oh-my-opencode-slim.json
```

## Version Differences

| Feature | Full | Slim |
|---------|------|------|
| Token usage | More | Less |
| Feature completeness | Most complete | Streamlined |
| Use case | Complex projects, architecture | Daily development, quick iteration |

## Uninstall

```bash
./uninstall.sh
```

Or manually:

```bash
rm -f ~/.local/bin/opencode-full
rm -f ~/.local/bin/opencode-slim
rm -f ~/.config/opencode/oh-my-opencode-slim.json
rm -f ~/.config/opencode/oh-my-opencode-full.json
```

## FAQ

### Q: After switching, it still loads the old version?

A: Make sure you use wrapper scripts (`opencode-full` / `opencode-slim`) instead of running `opencode` directly.

### Q: How to check which version is currently active?

```bash
cat ~/.config/opencode/opencode.json | jq '.plugin'
```

### Q: How to update Full / Slim versions?

```bash
# Update directly, wrapper doesn't lock versions
bunx oh-my-opencode@latest install       # Update Full
bunx oh-my-opencode-slim@latest install  # Update Slim
```

### Q: Where are Skills installed?

OpenCode Skills are located at `~/.config/opencode/skills/`, not `~/.agents/skills/`.

If you use `npx skills install`, it installs to `~/.agents/skills/` but OpenCode doesn't read that directory. Use OpenCode's built-in skills mechanism.

### Q: Running opencode-full/opencode-slim shows command not found?

PATH setting hasn't taken effect. Run:

```bash
# zsh
source ~/.zshrc

# bash
source ~/.bashrc
```

Or open a new terminal window.

## License

MIT License
