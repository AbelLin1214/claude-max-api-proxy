#!/usr/bin/env bash
set -e

# ── Claude Max API Proxy — Quick Install ──────────────────────────
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/AbelLin1214/claude-max-api-proxy/main/install.sh | bash -s -- --token YOUR_OAUTH_TOKEN
#   curl -fsSL ... | bash -s -- --api-key sk-ant-xxx --proxy-key my-secret
#   curl -fsSL ... | bash -s -- --token YOUR_TOKEN --port 8080

COMPOSE_URL="https://raw.githubusercontent.com/AbelLin1214/claude-max-api-proxy/main/docker-compose.yaml"
INSTALL_DIR="${INSTALL_DIR:-/opt/claude-max-api-proxy}"
PORT=3456
OAUTH_TOKEN=""
REFRESH_TOKEN=""
API_KEY=""
PROXY_KEY=""

# ── Parse arguments ───────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case $1 in
    --port)          PORT="$2"; shift 2 ;;
    --token)         OAUTH_TOKEN="$2"; shift 2 ;;
    --refresh-token) REFRESH_TOKEN="$2"; shift 2 ;;
    --api-key)       API_KEY="$2"; shift 2 ;;
    --proxy-key)     PROXY_KEY="$2"; shift 2 ;;
    --dir)           INSTALL_DIR="$2"; shift 2 ;;
    -h|--help)
      echo "Usage: install.sh [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --port PORT              Host port (default: 3456)"
      echo "  --token TOKEN            Claude Max/Pro OAuth token"
      echo "  --refresh-token TOKEN    OAuth refresh token (optional)"
      echo "  --api-key KEY            Anthropic Console API key"
      echo "  --proxy-key KEY          Proxy API key (clients must provide this to access the proxy)"
      echo "  --dir DIR                Install directory (default: /opt/claude-max-api-proxy)"
      echo "  -h, --help               Show this help"
      exit 0
      ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

# ── Checks ────────────────────────────────────────────────────────
if ! command -v docker &>/dev/null; then
  echo "Error: docker is not installed."
  echo "  Install: https://docs.docker.com/get-docker/"
  exit 1
fi

if ! docker compose version &>/dev/null; then
  echo "Error: docker compose is not available."
  echo "  Install: https://docs.docker.com/compose/install/"
  exit 1
fi

if [ -z "$OAUTH_TOKEN" ] && [ -z "$API_KEY" ]; then
  echo "Error: No authentication provided."
  echo "  Use --token YOUR_OAUTH_TOKEN  (Claude Max/Pro subscription)"
  echo "  Or  --api-key sk-ant-xxx      (Console API key)"
  exit 1
fi

# ── Create install directory ──────────────────────────────────────
echo "Installing to $INSTALL_DIR ..."
mkdir -p "$INSTALL_DIR"

# ── Download docker-compose.yaml ──────────────────────────────────
echo "Downloading docker-compose.yaml ..."
curl -fsSL "$COMPOSE_URL" -o "$INSTALL_DIR/docker-compose.yaml"

# ── Generate .env file with credentials ───────────────────────────
ENV_FILE="$INSTALL_DIR/.env"
cat > "$ENV_FILE" <<EOF
HOST=0.0.0.0
PORT=$PORT
EOF

if [ -n "$API_KEY" ]; then
  echo "ANTHROPIC_API_KEY=$API_KEY" >> "$ENV_FILE"
  AUTH_METHOD="ANTHROPIC_API_KEY"
else
  echo "CLAUDE_CODE_OAUTH_TOKEN=$OAUTH_TOKEN" >> "$ENV_FILE"
  [ -n "$REFRESH_TOKEN" ] && echo "CLAUDE_CODE_OAUTH_REFRESH_TOKEN=$REFRESH_TOKEN" >> "$ENV_FILE"
  AUTH_METHOD="CLAUDE_CODE_OAUTH_TOKEN"
fi

if [ -n "$PROXY_KEY" ]; then
  echo "API_KEY=$PROXY_KEY" >> "$ENV_FILE"
fi

chmod 600 "$ENV_FILE"

# ── Patch docker-compose.yaml with actual auth env vars ───────────
cd "$INSTALL_DIR"

if [ -n "$API_KEY" ]; then
  sed -i.bak 's|# - ANTHROPIC_API_KEY=.*|- ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}|' docker-compose.yaml
else
  sed -i.bak 's|# - CLAUDE_CODE_OAUTH_TOKEN=.*|- CLAUDE_CODE_OAUTH_TOKEN=${CLAUDE_CODE_OAUTH_TOKEN}|' docker-compose.yaml
  [ -n "$REFRESH_TOKEN" ] && sed -i.bak 's|# - CLAUDE_CODE_OAUTH_REFRESH_TOKEN=.*|- CLAUDE_CODE_OAUTH_REFRESH_TOKEN=${CLAUDE_CODE_OAUTH_REFRESH_TOKEN}|' docker-compose.yaml
fi

if [ -n "$PROXY_KEY" ]; then
  sed -i.bak 's|# - API_KEY=.*|- API_KEY=${API_KEY}|' docker-compose.yaml
fi

# Patch port if non-default
if [ "$PORT" != "3456" ]; then
  sed -i.bak "s|\"\\${PORT:-3456}:3456\"|\"${PORT}:3456\"|" docker-compose.yaml
fi

rm -f docker-compose.yaml.bak

# ── Deploy ────────────────────────────────────────────────────────
echo "Starting services ..."
docker compose pull
docker compose up -d

echo ""
echo "========================================="
echo " Claude Max API Proxy is running!"
echo "========================================="
echo ""
echo "  Auth:      $AUTH_METHOD"
if [ -n "$PROXY_KEY" ]; then
echo "  Proxy key: enabled (API_KEY)"
fi
echo "  Endpoint:  http://localhost:${PORT}/v1/chat/completions"
echo "  Health:    http://localhost:${PORT}/health"
echo "  Models:    http://localhost:${PORT}/v1/models"
echo "  Directory: $INSTALL_DIR"
echo ""
echo "Test:"
if [ -n "$PROXY_KEY" ]; then
echo "  curl -X POST http://localhost:${PORT}/v1/chat/completions \\"
echo "    -H 'Content-Type: application/json' \\"
echo "    -H 'Authorization: Bearer YOUR_PROXY_KEY' \\"
echo "    -d '{\"model\": \"claude-sonnet-4\", \"messages\": [{\"role\": \"user\", \"content\": \"Hello!\"}]}'"
else
echo "  curl -X POST http://localhost:${PORT}/v1/chat/completions \\"
echo "    -H 'Content-Type: application/json' \\"
echo "    -d '{\"model\": \"claude-sonnet-4\", \"messages\": [{\"role\": \"user\", \"content\": \"Hello!\"}]}'"
fi
echo ""
echo "Manage:"
echo "  cd $INSTALL_DIR"
echo "  docker compose logs -f     # View logs"
echo "  docker compose restart     # Restart"
echo "  docker compose down        # Stop"
echo "  vim .env                   # Edit credentials"
echo "  vim docker-compose.yaml    # Add more accounts"
