# Stage 1: Build
FROM node:20-slim AS builder

WORKDIR /app

COPY package.json package-lock.json tsconfig.json ./
RUN npm ci

COPY src/ src/
RUN npm run build

# Stage 2: Runtime
FROM node:20-slim

# Install Claude Code CLI globally
RUN npm install -g @anthropic-ai/claude-code

# Create non-root user
RUN useradd -m -s /bin/sh claude
WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci --omit=dev

COPY --from=builder /app/dist/ dist/
COPY docker-entrypoint.sh /usr/local/bin/

# Ensure config dir exists with correct ownership
RUN mkdir -p /home/claude/.claude && chown -R claude:claude /home/claude/.claude

USER claude

# Listen on all interfaces so Docker port mapping works
ENV HOST=0.0.0.0
ENV PORT=3456
ENV CLAUDE_CONFIG_DIR=/home/claude/.claude

EXPOSE 3456

ENTRYPOINT ["docker-entrypoint.sh"]
