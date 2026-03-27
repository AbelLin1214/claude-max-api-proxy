#!/bin/sh
set -e

CLAUDE_CONFIG_DIR="${CLAUDE_CONFIG_DIR:-/home/claude/.claude}"
mkdir -p "$CLAUDE_CONFIG_DIR"

# ── Authentication setup ──────────────────────────────────────────
# Priority:
#   1. ANTHROPIC_API_KEY        — Console API key (pay-per-use)
#   2. CLAUDE_OAUTH_TOKEN       — OAuth token from Claude Max/Pro subscription
#   3. Mounted .credentials.json — Pre-existing credentials file
#
# For Claude Max subscribers: run `claude auth login` on any machine,
# then copy ~/.claude/.credentials.json (Linux) and mount it into the
# container, OR extract the oauth token and pass it as CLAUDE_OAUTH_TOKEN.

if [ -n "$ANTHROPIC_API_KEY" ]; then
  echo "[entrypoint] Using ANTHROPIC_API_KEY for authentication"

elif [ -n "$CLAUDE_OAUTH_TOKEN" ]; then
  echo "[entrypoint] Writing OAuth credentials from CLAUDE_OAUTH_TOKEN"
  cat > "$CLAUDE_CONFIG_DIR/.credentials.json" <<CRED
{
  "claudeAiOauth": {
    "accessToken": "${CLAUDE_OAUTH_TOKEN}",
    "expiresAt": "9999-12-31T23:59:59.999Z",
    "refreshToken": "${CLAUDE_OAUTH_REFRESH_TOKEN:-}",
    "scopes": "user:inference user:profile"
  }
}
CRED
  chmod 600 "$CLAUDE_CONFIG_DIR/.credentials.json"

elif [ -f "$CLAUDE_CONFIG_DIR/.credentials.json" ]; then
  echo "[entrypoint] Using mounted credentials file"

else
  echo "[entrypoint] WARNING: No authentication configured."
  echo "  Set one of:"
  echo "    - ANTHROPIC_API_KEY        (Console API key)"
  echo "    - CLAUDE_OAUTH_TOKEN       (OAuth access token from Max/Pro subscription)"
  echo "    - Mount .credentials.json  (volume mount)"
  echo ""
  echo "  See README for details on extracting credentials."
fi

# ── Launch server ─────────────────────────────────────────────────
exec node dist/server/standalone.js "$@"
