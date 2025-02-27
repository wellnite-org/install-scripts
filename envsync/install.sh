#!/bin/bash

echo "🚀 Installing @wellnite-org/envsync..."

# Configuration
NPMRC_FILE="$HOME/.npmrc"
ORG_NAME="wellnite-org"
REGISTRY_LINE="@${ORG_NAME}:registry=https://npm.pkg.github.com/"
AUTH_LINE="//npm.pkg.github.com/:_authToken="
ENV_VAR_NAME="GITHUB_TOKEN_WELLNITE"
GITHUB_TOKEN_URL="https://github.com/settings/tokens"

# Ensure .npmrc file exists
touch "$NPMRC_FILE"

# Ensure script is running interactively
if [[ ! -t 0 ]]; then
    echo "⚠️  This script must be run interactively to enter the GitHub token."
    echo "   Try running it manually: curl -fsSL <URL> -o install.sh && bash install.sh"
    exit 1
fi

# Detect OS for compatibility
OS="$(uname -s)"
case "$OS" in
    Darwin*)  SED_CMD="sed -i ''"  ;;  # macOS
    Linux*)   SED_CMD="sed -i"  ;;    # Linux
    CYGWIN*|MINGW*|MSYS*)  SED_CMD="sed -i"  ;;  # Git Bash on Windows
    *) echo "⚠️ Unsupported OS: $OS"; exit 1 ;;
esac

# Function to update .npmrc safely
update_npmrc() {
  local key="$1"
  local value="$2"

  if grep -qF "$key" "$NPMRC_FILE"; then
    # Update existing entry
    $SED_CMD "s|^$key.*|$key$value|" "$NPMRC_FILE"
  else
    # Add new entry
    echo "$key$value" >> "$NPMRC_FILE"
  fi
}

# Ensure registry is set
update_npmrc "$REGISTRY_LINE" ""

# Check if the environment variable is set
if [ -z "${!ENV_VAR_NAME}" ]; then
  echo ""
  echo "⚠️  GitHub token required for @$ORG_NAME package access."
  echo ""
  echo "📌 Generate a GitHub personal access token (classic) at:"
  echo "   👉 $GITHUB_TOKEN_URL"
  echo ""
  echo "✅ Ensure the token has the 'read:packages' scope."
  echo "🔒 Your token will not be displayed while typing."
  echo ""

  while true; do
    read -r -s -p "Enter your GitHub token: " TOKEN
    echo ""

    if [ -n "$TOKEN" ]; then
      export $ENV_VAR_NAME="$TOKEN"  # Set in the current session
      echo "export $ENV_VAR_NAME=\"$TOKEN\"" >> "$HOME/.bashrc"  # Persist in .bashrc
      if [[ -f "$HOME/.zshrc" ]]; then
        echo "export $ENV_VAR_NAME=\"$TOKEN\"" >> "$HOME/.zshrc"  # Persist in .zshrc for macOS users
      fi
      break
    else
      echo "❌ No token entered. Please enter a valid token."
    fi
  done
fi

# Now update .npmrc with the environment variable reference
update_npmrc "$AUTH_LINE" "\${$ENV_VAR_NAME}"

# Confirm before installing
echo "📦 Installing @${ORG_NAME}/envsync..."
sleep 1  # Small delay for clarity

# Install the package globally
npm install -g @${ORG_NAME}/envsync

# Verify installation
if command -v wellnite-envsync &> /dev/null; then
    echo "✅ Installation successful! Run 'wellnite-envsync init' to start."
else
    echo "❌ Installation failed. Please check the error messages above."
fi
