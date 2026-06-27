#!/usr/bin/env bash
# Decide whether the user is already looking at THIS session's window,
# in which case the caller should suppress its notification.
#
#   exit 0  -> this session's window/pane is focused (SUPPRESS the notification)
#   exit 1  -> user is elsewhere (SEND the notification)
#
# Arg 1: the session cwd (from the hook JSON payload).
# Arg 2: the host app's System Events process name (from resolve-app.sh).
# Arg 3: the iTerm session id (GUID), if any. Empty outside iTerm.
#
# Two strategies, best-first (mirroring focus-window.sh):
#   1. iTerm only: if a session id is given, ask iTerm for the *currently
#      focused* session id and compare it to ours. This is exact — it tells the
#      right tab/split-pane apart from others sharing the same cwd, which (2)
#      cannot. The comparison is authoritative for iTerm, so it never falls
#      through to (2): a mismatch (or any error) means NOTIFY, never a false
#      suppress on a same-dir sibling tab.
#   2. Generic title match: the frontmost process must be the host app, and the
#      frontmost window's title must contain a meaningful segment of the session
#      path (e.g. ".claude", or "myrepo" for a multi-root "myrepo (Workspace)"
#      window). Generic path segments (Users, home dir, Documents, git, ...) are
#      ignored to avoid false matches. Used for non-iTerm hosts (VS Code has no
#      AppleScript window API; Terminal.app) and when no session id is given.
#
# On any uncertainty (incl. unknown host app) we default to NOTIFYING.

cwd="$1"
proc="$2"
iterm_session="$3"
[ -z "$cwd" ] && exit 1
[ -z "$proc" ] && exit 1

# Strategy 1 — iTerm native, by exact session id. Confirm iTerm is the frontmost
# app, then ask it for the focused session of the focused window (which is the
# visible focused split pane). Equal id -> suppress; anything else -> notify.
if [ "$proc" = "iTerm2" ] && [ -n "$iterm_session" ]; then
  focused=$(osascript <<'APPLESCRIPT' 2>/dev/null
tell application "System Events"
  if name of (first process whose frontmost is true) is not "iTerm2" then return ""
end tell
tell application "iTerm2" to return id of current session of current window
APPLESCRIPT
)
  # Empty = not frontmost / iTerm error / TCC denial -> default to NOTIFY.
  [ "$focused" = "$iterm_session" ] && exit 0
  exit 1
fi

front=$(osascript <<'APPLESCRIPT' 2>/dev/null
tell application "System Events"
  set p to first process whose frontmost is true
  set pname to name of p
  set wtitle to ""
  try
    set wtitle to title of front window of p
  end try
  return pname & "||" & wtitle
end tell
APPLESCRIPT
)
[ -z "$front" ] && exit 1

pname="${front%%||*}"
title="${front#*||}"

# Frontmost app must be the host app.
[ "$pname" = "$proc" ] || exit 1
[ -z "$title" ] && exit 1

# Match meaningful path segments against the frontmost window title.
deny=" Users $(basename "$HOME") Documents git code src Desktop repos tmp var home "
IFS='/' read -ra segs <<< "$cwd"
for seg in "${segs[@]}"; do
  [ -z "$seg" ] && continue
  case "$deny" in *" $seg "*) continue ;; esac   # skip generic segments
  case "$title" in *"$seg"*) exit 0 ;; esac       # frontmost window is this project's
done

exit 1
