#!/usr/bin/env bash
# Decide whether the user is already looking at THIS session's VS Code window,
# in which case the caller should suppress its notification.
#
#   exit 0  -> this project's window is frontmost (SUPPRESS the notification)
#   exit 1  -> user is elsewhere (SEND the notification)
#
# Arg 1: the session cwd (from the hook JSON payload).
#
# The frontmost process must be VS Code ("Code"), and the frontmost window's
# title must contain a meaningful segment of the session path (e.g. ".claude",
# or "myrepo" for a multi-root "myrepo (Workspace)" window). Generic path
# segments (Users, home dir, Documents, git, ...) are ignored to avoid false
# matches. Process name and window title are read in one System Events call so
# they can't disagree. On any uncertainty we default to NOTIFYING.

cwd="$1"
[ -z "$cwd" ] && exit 1

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

# Frontmost app must be VS Code (its process name is "Code").
[ "$pname" = "Code" ] || exit 1
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
