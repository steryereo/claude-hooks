#!/usr/bin/env bash
# Notification hook: notify when Claude Code needs attention.
# Passes the real notification message through, and tailors the title/sound
# to the notification_type (permission prompt vs. idle, etc.).
# Reads the hook JSON payload from stdin.

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

input=$(cat)
notifier=$(command -v terminal-notifier || echo /opt/homebrew/bin/terminal-notifier)

ntype=$(printf '%s' "$input" | jq -r '.notification_type // ""')
message=$(printf '%s' "$input" | jq -r '.message // "needs your attention"' | tr '\n' ' ' | cut -c1-200)
cwd=$(printf '%s' "$input" | jq -r '.cwd // ""')

# Resolve the host terminal/IDE (VS Code, iTerm, Terminal, ...); empty if unknown.
IFS='|' read -r app proc <<< "$("$HOOK_DIR/resolve-app.sh")"

# iTerm session id (GUID after the wXtYpZ: prefix); empty outside iTerm. Lets the
# click target the exact originating window even with same-dir duplicates.
iterm_sid="${ITERM_SESSION_ID##*:}"

# Skip the notification if the user is already looking at this project's window.
if "$HOOK_DIR/window-focused.sh" "$cwd" "$proc" "$iterm_sid"; then
  exit 0
fi

proj=$(basename "$cwd" 2>/dev/null)
[ -z "$proj" ] && proj="Claude Code"

title="Claude Code"
sound="Ping"
case "$ntype" in
  permission_prompt) title="Claude Code · permission needed" ;;
  idle_prompt)       title="Claude Code · waiting for you"; sound="Funk" ;;
esac

# Click-to-focus only when we recognise the host app.
focus=()
[ -n "$app" ] && [ -n "$proc" ] && focus=(-execute "$HOOK_DIR/focus-window.sh '$app' '$proc' '$proj' '$iterm_sid'")

"$notifier" -message "$message" -title "$title" \
  "${focus[@]}" -sound "$sound" 2>/dev/null || true
