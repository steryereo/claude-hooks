#!/usr/bin/env bash
# Stop hook: notify when Claude Code finishes responding.
# Title shows the project folder; body shows the last line of Claude's reply.
# Reads the hook JSON payload from stdin.

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

input=$(cat)
notifier=$(command -v terminal-notifier || echo /opt/homebrew/bin/terminal-notifier)

cwd=$(printf '%s' "$input" | jq -r '.cwd // ""')
transcript=$(printf '%s' "$input" | jq -r '.transcript_path // ""')

# Resolve the host terminal/IDE (VS Code, iTerm, Terminal, ...); empty if unknown.
IFS='|' read -r app proc <<< "$("$HOOK_DIR/resolve-app.sh")"

# iTerm session id (GUID after the wXtYpZ: prefix); empty outside iTerm. Lets the
# click target the exact originating window even with same-dir duplicates.
iterm_sid="${ITERM_SESSION_ID##*:}"

# Skip the notification if the user is already looking at this project's window.
if "$HOOK_DIR/window-focused.sh" "$cwd" "$proc"; then
  exit 0
fi

proj=$(basename "$cwd" 2>/dev/null)
[ -z "$proj" ] && proj="Claude Code"

msg="Ready"
if [ -n "$transcript" ] && [ -f "$transcript" ]; then
  last=$(tail -n 100 "$transcript" \
    | jq -r 'select(.type=="assistant") | .message.content[]? | select(.type=="text") | .text' 2>/dev/null \
    | tail -1 | tr '\n' ' ' | cut -c1-150)
  [ -n "$last" ] && msg="$last"
fi

# Click-to-focus only when we recognise the host app.
focus=()
[ -n "$app" ] && [ -n "$proc" ] && focus=(-execute "$HOOK_DIR/focus-window.sh '$app' '$proc' '$proj' '$iterm_sid'")

"$notifier" -message "$msg" -title "Claude Code ✓ $proj" \
  "${focus[@]}" -sound 'Glass' 2>/dev/null || true
