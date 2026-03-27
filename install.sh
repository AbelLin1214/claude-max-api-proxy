#!/usr/bin/env bash
set -e

# ── Claude Max API Proxy — Quick Install ──────────────────────────
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/AbelLin1214/claude-max-api-proxy/main/install.sh | bash
#
#   With options:
#   curl -fsSL ... | bash -s -- --port 8080 --token YOUR_OAUTH_TOKEN
#   curl -fsSL ... | bash -s -- --api-key sk-ant-xxx

IMAGE="abellin1214/claude-max-api-proxy:latest"
CONTAINER_NAME="claude-max-api-proxy"
PORT=3456
OAUTH_TOKEN=""
API_KEY=""

# ── Parse arguments ───────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case $1 in
    --port)       PORT="$2"; shift 2 ;;
    --token)      OAUTH_TOKEN="$2"; shift 2 ;;
    --api-key)    API_KEY="$2"; shift 2 ;;
    --image)      IMAGE="$2"; shift 2 ;;
    --name)       CONTAINER_NAME="$2"; shift 2 ;;
    -h|--help)
      echo "Usage: install.sh [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --port PORT          Host port (default: 3456)"
      echo "  --token TOKEN        Claude Max/Pro OAuth token (CLAUDE_CODE_OAUTH_TOKEN)"
      echo "  --api-key KEY        Anthropic Console API key (ANTHROPIC_API_KEY)"
      echo "  --image IMAGE        Docker image (default: $IMAGE)"
      echo "  --name NAME          Container name (default: $CONTAINER_NAME)"
      echo "  -h, --help           Show this help"
      exit 0
      ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

# ── Checks ────────────────────────────────────────────────────────
if ! command -v docker &>/dev/null; then
  echo "Error: docker is not installed. Install it first: https://docs.docker.com/get-docker/"
  exit 1
fi

if [ -z "$OAUTH_TOKEN" ] && [ -z "$API_KEY" ]; then
  echo "Error: No authentication provided."
  echo "  Use --token YOUR_OAUTH_TOKEN  (Claude Max/Pro subscription)"
  echo "  Or  --api-key sk-ant-xxx      (Console API key)"
  exit 1
fi

# ── Build env args ────────────────────────────────────────────────
ENV_ARGS="-e HOST=0.0.0.0 -e PORT=3456"
if [ -n "$API_KEY" ]; then
  ENV_ARGS="$ENV_ARGS -e ANTHROPIC_API_KEY=$API_KEY"
  AUTH_METHOD="ANTHROPIC_API_KEY"
else
  ENV_ARGS="$ENV_ARGS -e CLAUDE_CODE_OAUTH_TOKEN=$OAUTH_TOKEN"
  AUTH_METHOD="CLAUDE_CODE_OAUTH_TOKEN"
fi

# ── Deploy ────────────────────────────────────────────────────────
echo "Pulling $IMAGE ..."
docker pull "$IMAGE"

# Stop existing container if running
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  echo "Stopping existing container '$CONTAINER_NAME' ..."
  docker rm -f "$CONTAINER_NAME" >/dev/null
fi

echo "Starting container ..."
docker run -d \
  --name "$CONTAINER_NAME" \
  --restart unless-stopped \
  -p "${PORT}:3456" \
  $ENV_ARGS \
  "$IMAGE"

echo ""
echo "========================================="
echo " Claude Max API Proxy is running!"
echo "========================================="
echo ""
echo "  Auth:     $AUTH_METHOD"
echo "  Endpoint: http://localhost:${PORT}/v1/chat/completions"
echo "  Health:   http://localhost:${PORT}/health"
echo "  Models:   http://localhost:${PORT}/v1/models"
echo ""
echo "Test:"
echo "  curl -X POST http://localhost:${PORT}/v1/chat/completions \\"
echo "    -H 'Content-Type: application/json' \\"
echo "    -d '{\"model\": \"claude-sonnet-4\", \"messages\": [{\"role\": \"user\", \"content\": \"Hello!\"}]}'"
echo ""
echo "Logs:  docker logs -f $CONTAINER_NAME"
echo "Stop:  docker rm -f $CONTAINER_NAME"
