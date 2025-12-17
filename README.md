**Termux install script** that builds **Codex CLI from source (Rust)** (recommended on Android because the npm install path can break on `android` due to the ripgrep dependency). ([GitHub][1])
It defaults to the **latest stable tag `rust-v0.73.0`** (current “Latest” release on GitHub). ([GitHub][2])

```bash
#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

# Default to latest stable release tag (override with --tag or CODEX_TAG env var)
CODEX_TAG="${CODEX_TAG:-rust-v0.73.0}"

# If you want a lower-memory build profile (usually not needed for 24GB RAM),
# run the script with: --termux-profile
USE_TERMUX_PROFILE=0

# If you want the script to set Codex to API-key auth (recommended if ChatGPT login fails on Termux),
# run with: --configure-apikey
CONFIGURE_APIKEY=0

usage() {
  cat <<'EOF'
Install OpenAI Codex CLI on Termux (Android) by building from source (Rust).

Usage:
  ./install_codex_termux.sh [--tag rust-vX.Y.Z] [--termux-profile] [--configure-apikey]

Options:
  --tag <tag>            Git tag to install (default: rust-v0.73.0)
  --termux-profile       Create/use a low-memory Cargo profile named "termux"
  --configure-apikey     Set preferred_auth_method="apikey" in ~/.codex/config.toml (does not write your key)

Notes:
  - If you want API key auth, export OPENAI_API_KEY in your shell profile yourself.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --tag) CODEX_TAG="${2:-}"; shift 2;;
    --termux-profile) USE_TERMUX_PROFILE=1; shift;;
    --configure-apikey) CONFIGURE_APIKEY=1; shift;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown arg: $1"; usage; exit 1;;
  esac
done

echo "[1/6] Updating Termux packages..."
pkg update -y
pkg upgrade -y

echo "[2/6] Installing build dependencies..."
pkg install -y rust git clang make pkg-config openssl ca-certificates

# Optional but useful: system ripgrep (many tools assume rg exists)
pkg install -y ripgrep || true

echo "[3/6] Ensuring Cargo bin is on PATH..."
PROFILE_FILE="$HOME/.profile"
PATH_LINE='export PATH="$HOME/.cargo/bin:$PATH"'
touch "$PROFILE_FILE"
grep -qxF "$PATH_LINE" "$PROFILE_FILE" || echo "$PATH_LINE" >> "$PROFILE_FILE"
# shellcheck disable=SC1090
source "$PROFILE_FILE"

if [[ "$USE_TERMUX_PROFILE" -eq 1 ]]; then
  echo "[4/6] Creating low-memory Cargo profile 'termux'..."
  mkdir -p "$HOME/.cargo"
  CARGO_CFG="$HOME/.cargo/config.toml"
  touch "$CARGO_CFG"

  # Add profile only if missing
  if ! grep -q '^\[profile\.termux\]' "$CARGO_CFG"; then
    cat >> "$CARGO_CFG" <<'EOF'

[profile.termux]
inherits = "release"
lto = "off"
codegen-units = 8
opt-level = "s"
EOF
  fi
fi

echo "[5/6] Installing Codex CLI from source (tag: $CODEX_TAG)..."
if [[ "$USE_TERMUX_PROFILE" -eq 1 ]]; then
  cargo install --git https://github.com/openai/codex --tag "$CODEX_TAG" codex-cli --force --locked --profile termux
else
  cargo install --git https://github.com/openai/codex --tag "$CODEX_TAG" codex-cli --force --locked
fi

echo "[6/6] Verifying install..."
command -v codex >/dev/null
codex --version || true

if [[ "$CONFIGURE_APIKEY" -eq 1 ]]; then
  echo "Configuring ~/.codex/config.toml to prefer API key auth..."
  mkdir -p "$HOME/.codex"
  CFG="$HOME/.codex/config.toml"
  touch "$CFG"

  # Replace existing preferred_auth_method line or append it
  if grep -q '^preferred_auth_method' "$CFG"; then
    sed -i 's/^preferred_auth_method.*/preferred_auth_method = "apikey"/' "$CFG"
  else
    echo 'preferred_auth_method = "apikey"' >> "$CFG"
  fi

  echo "Done. Now export your key (example):"
  echo '  echo '\''export OPENAI_API_KEY="YOUR_KEY_HERE"'\'' >> ~/.profile && source ~/.profile'
fi

echo
echo "All done ✅  Try:"
echo "  codex"
echo "If ChatGPT login fails on Termux, use API key auth (preferred_auth_method=\"apikey\")."
```

### Run it

```bash
nano install_codex_termux.sh
chmod +x install_codex_termux.sh
./install_codex_termux.sh
```

### If you want API-key mode (often best on Termux)

Codex uses `~/.codex/config.toml`, and you can set `preferred_auth_method = "apikey"` plus export `OPENAI_API_KEY`. ([OpenAI Developers][3])
Run:

```bash
./install_codex_termux.sh --configure-apikey
```

For tweak the script to automatically select the newest **stable** `rust-v*` tag (skipping `-alpha` tags) by scraping the releases page. ([GitHub][2])

[1]: https://github.com/microsoft/vscode-ripgrep/issues/76?utm_source=chatgpt.com "Support system ripgrep on Android (Termux) · Issue #76"
[2]: https://github.com/openai/codex/releases "Releases · openai/codex · GitHub"
[3]: https://developers.openai.com/codex/local-config/?utm_source=chatgpt.com "Configuring Codex"
