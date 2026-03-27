#!/bin/sh
set -e

# ── Authentication ────────────────────────────────────────────────
# Claude Code CLI natively reads these env vars (no files needed):
#
#   ANTHROPIC_API_KEY                — Console API key (pay-per-use)
#   CLAUDE_CODE_OAUTH_TOKEN          — OAuth access token (Max/Pro subscription)
#   CLAUDE_CODE_OAUTH_REFRESH_TOKEN  — OAuth refresh token (optional, for auto-renewal)
#
# How to get your OAuth token (Max/Pro subscribers):
#   1. Run `claude auth login` on any machine
#   2. Run `claude auth status` to confirm login
#   3. On Linux: token is in ~/.claude/.credentials.json
#      On macOS: token is in the system Keychain (search "claude" in Keychain Access)
#   4. Pass the token as CLAUDE_CODE_OAUTH_TOKEN env var

if [ -n "$ANTHROPIC_API_KEY" ]; then
  echo "[entrypoint] Auth: ANTHROPIC_API_KEY (Console API key)"
elif [ -n "$CLAUDE_CODE_OAUTH_TOKEN" ]; then
  echo "[entrypoint] Auth: CLAUDE_CODE_OAUTH_TOKEN (Max/Pro subscription)"
else
  echo "[entrypoint] WARNING: No authentication configured."
  echo "  Set one of:"
  echo "    ANTHROPIC_API_KEY               — Console API key (pay-per-use)"
  echo "    CLAUDE_CODE_OAUTH_TOKEN         — OAuth token (Max/Pro subscription)"
fi

# ── Launch server ─────────────────────────────────────────────────
exec node dist/server/standalone.js "$@"
