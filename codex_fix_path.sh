#!/data/data/com.termux/files/usr/bin/bash

set -e

echo "🔧 Codex Termux Fix (zsh + bash)"

CARGO_BIN="$HOME/.cargo/bin"
LOCAL_BIN="$HOME/.local/bin"

ZSH_RC="$HOME/.zshrc"
BASH_RC="$HOME/.bashrc"
PROFILE_RC="$HOME/.profile"

# Ensure dirs
mkdir -p "$CARGO_BIN" "$LOCAL_BIN"

# Ensure codex exists
if [ ! -x "$CARGO_BIN/codex" ]; then
  echo "❌ Codex not found at $CARGO_BIN/codex"
  exit 1
fi

# Stable symlink
ln -sf "$CARGO_BIN/codex" "$LOCAL_BIN/codex"
chmod +x "$LOCAL_BIN/codex"

echo "✅ Codex linked to $LOCAL_BIN/codex"

# Config block
CONFIG_BLOCK='
### CODEX TERMUX FIX ###
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
export ANDROID_DATA=/data
export ANDROID_ROOT=/system
### END CODEX TERMUX FIX ###
'

# Apply to all relevant shells (idempotent)
for rc in "$ZSH_RC" "$BASH_RC" "$PROFILE_RC"; do
  if [ -f "$rc" ] && grep -q "CODEX TERMUX FIX" "$rc"; then
    echo "ℹ️ Already patched: $rc"
  else
    echo "$CONFIG_BLOCK" >> "$rc"
    echo "✅ Patched: $rc"
  fi
done

# Clear shell cache
hash -r 2>/dev/null || true

echo
echo "🎉 Codex PATH fixed for zsh & bash"
echo "🔁 Restart Termux OR run:"
echo "   source ~/.zshrc   # zsh"
echo "   source ~/.bashrc  # bash"
echo
echo "🚀 Test:"
echo "   which codex"
echo "   codex --version"