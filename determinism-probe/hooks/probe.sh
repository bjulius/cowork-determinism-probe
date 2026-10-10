#!/usr/bin/env bash
# determinism-probe hook. Usage: probe.sh <EventName>; reads the hook payload JSON on stdin.
# Every call appends one line to probe-hook-log.txt so you can see, outside the chat, that the hook ran.
event="$1"
input=$(cat)
log="${CLAUDE_PROJECT_DIR:-$PWD}/probe-hook-log.txt"
ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
tool=$(printf '%s' "$input" | sed -n 's/.*"tool_name" *: *"\([^"]*\)".*/\1/p' | head -n 1)
# which agent made the call (set for subagent calls), and which agent a spawn asked for
caller=$(printf '%s' "$input" | sed -n 's/.*"agent_type" *: *"\([^"]*\)".*/\1/p' | head -n 1)
spawn=$(printf '%s' "$input" | sed -n 's/.*"subagent_type" *: *"\([^"]*\)".*/\1/p' | head -n 1)
tool="$tool caller=${caller:-main}${spawn:+ spawns=$spawn}"

case "$event" in
  SessionStart)
    nonce="PROBE-$(date -u +%H%M%S)-$RANDOM"
    echo "$ts SessionStart nonce=$nonce host=$(uname -s) pwd=$PWD" >> "$log"
    # stdout from a SessionStart command hook is added to the model's context
    echo "determinism-probe SessionStart hook ran at $ts."
    echo "Session nonce: $nonce"
    echo "Hook environment: uname=$(uname -a) | pwd=$PWD | CLAUDE_PROJECT_DIR=${CLAUDE_PROJECT_DIR:-unset} | CLAUDE_PLUGIN_ROOT=${CLAUDE_PLUGIN_ROOT:-unset} | python3=$(python3 --version 2>&1 | head -n 1)"
    echo "Hook log file: $log"
    ;;
  PreToolUse)
    # Deterministic control: any tool call whose input mentions LOCKED is refused, whatever the model intends.
    if printf '%s' "$input" | grep -q 'LOCKED'; then
      echo "$ts PreToolUse tool=$tool decision=BLOCK" >> "$log"
      echo "determinism-probe: blocked by command hook. Files named LOCKED may not be touched." >&2
      exit 2
    fi
    echo "$ts PreToolUse tool=$tool decision=allow" >> "$log"
    ;;
  PostToolUse)
    echo "$ts PostToolUse tool=$tool" >> "$log"
    ;;
esac
exit 0
