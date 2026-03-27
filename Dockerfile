# Stage 1: Build
FROM node:20-slim AS builder

WORKDIR /app

COPY package.json package-lock.json tsconfig.json ./
RUN npm ci

COPY src/ src/
RUN npm run build

# Stage 2: Runtime
FROM node:20-slim

# Install Claude Code CLI
RUN npm install -g @anthropic-ai/claude-code

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci --omit=dev

COPY --from=builder /app/dist/ dist/

# Listen on all interfaces so Docker port mapping works
ENV HOST=0.0.0.0
ENV PORT=3456

EXPOSE 3456

CMD ["node", "dist/server/standalone.js"]
