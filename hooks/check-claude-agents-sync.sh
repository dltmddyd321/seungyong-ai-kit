#!/usr/bin/env bash
set -euo pipefail

input="$(cat)"
file_path="$(echo "$input" | jq -r '.tool_input.file_path // .tool_response.filePath // empty')"

if [ -z "$file_path" ] || [ "$(basename "$file_path")" != "CLAUDE.md" ]; then
  exit 0
fi

root="$(git -C "$(dirname "$file_path")" rev-parse --show-toplevel 2>/dev/null || dirname "$file_path")"
claude_md="$root/CLAUDE.md"
agents_md="$root/AGENTS.md"

if [ ! -f "$claude_md" ] || [ ! -f "$agents_md" ]; then
  exit 0
fi

if grep -qx '@AGENTS.md' "$claude_md"; then
  exit 0
fi

if diff -q "$claude_md" "$agents_md" >/dev/null 2>&1; then
  exit 0
fi

diff_text="$(diff "$claude_md" "$agents_md" || true)"

jq -n \
  --arg msg "CLAUDE.md changed — AGENTS.md is now out of sync. Sync it to match." \
  --arg ctx "CLAUDE.md was just edited and now differs from AGENTS.md (the Codex-compatible mirror). These two files must stay in sync. Update AGENTS.md now to match CLAUDE.md's substantive rules (adapt only genuinely tool-specific references). Diff:
$diff_text" \
  '{systemMessage: $msg, hookSpecificOutput: {hookEventName: "PostToolUse", additionalContext: $ctx}}'
