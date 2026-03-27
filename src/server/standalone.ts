#!/usr/bin/env node
/**
 * Standalone server for testing without Clawdbot
 *
 * Usage:
 *   npm run start
 *   # or
 *   node dist/server/standalone.js [port]
 */

import { startServer, stopServer } from "./index.js";
import { verifyClaude, verifyAuth } from "../subprocess/manager.js";

const DEFAULT_PORT = 3456;

async function main(): Promise<void> {
  console.log("Claude Code CLI Provider - Standalone Server");
  console.log("============================================\n");

  // Parse port from command line or PORT env var
  const port = parseInt(process.argv[2] || process.env.PORT || String(DEFAULT_PORT), 10);
  if (isNaN(port) || port < 1 || port > 65535) {
    console.error(`Invalid port: ${process.argv[2]}`);
    process.exit(1);
  }

  // Verify Claude CLI
  console.log("Checking Claude CLI...");
  const cliCheck = await verifyClaude();
  if (!cliCheck.ok) {
    console.error(`Error: ${cliCheck.error}`);
    process.exit(1);
  }
  console.log(`  Claude CLI: ${cliCheck.version || "OK"}`);

  // Verify authentication
  console.log("Checking authentication...");
  const authCheck = await verifyAuth();
  if (!authCheck.ok) {
    console.error(`Error: ${authCheck.error}`);
    console.error("Please run: claude auth login");
    process.exit(1);
  }
  console.log("  Authentication: OK\n");

  // Start server
  const host = process.env.HOST || "127.0.0.1";
  try {
    await startServer({ port, host });
    const apiKeyNote = process.env.API_KEY ? `\n  Add: -H "Authorization: Bearer YOUR_API_KEY"\n` : "";
    console.log(`\nServer ready.${apiKeyNote}\nTest with:`);
    console.log(`  curl -X POST http://localhost:${port}/v1/chat/completions \\`);
    console.log(`    -H "Content-Type: application/json" \\`);
    if (process.env.API_KEY) {
      console.log(`    -H "Authorization: Bearer YOUR_API_KEY" \\`);
    }
    console.log(`    -d '{"model": "claude-sonnet-4", "messages": [{"role": "user", "content": "Hello!"}]}'`);
    console.log("\nPress Ctrl+C to stop.\n");
  } catch (err) {
    console.error("Failed to start server:", err);
    process.exit(1);
  }

  // Handle graceful shutdown
  const shutdown = async () => {
    console.log("\nShutting down...");
    await stopServer();
    process.exit(0);
  };

  process.on("SIGINT", shutdown);
  process.on("SIGTERM", shutdown);
}

main().catch((err) => {
  console.error("Unexpected error:", err);
  process.exit(1);
});
