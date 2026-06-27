#!/usr/bin/env bash
# Focus the window whose title contains the given substring (the project folder
# name). Invoked by `terminal-notifier -execute` when a notification is clicked.
# Most editors/terminals put the workspace folder name in the window title, so
# matching on the project basename lands on the right window. If nothing matches
# (e.g. a terminal that omits the folder from its title), the host app is still
# brought forward to its current window — a best-effort fallback.
#
# Usage: focus-window.sh "<app-name>" "<process-name>" "<title-substring>"
#   app-name / process-name come from resolve-app.sh, baked in at hook time
#   (the host app can't be detected on click — $TERM_PROGRAM is gone by then).
#
# First click triggers a one-time macOS prompt: "terminal-notifier wants to
# control <App> / System Events" — approve it for this to work.

app="$1"
proc="$2"
needle="$3"

[ -z "$app" ] || [ -z "$proc" ] || [ -z "$needle" ] && exit 0

osascript - "$app" "$proc" "$needle" <<'APPLESCRIPT' 2>/dev/null
on run argv
  set appName to item 1 of argv
  set procName to item 2 of argv
  set needle to item 3 of argv
  -- Unconditional activate is the intentional fallback: even if no window title
  -- matches the needle (e.g. a terminal that doesn't show the project folder),
  -- the host app still comes forward to its current window — better than nothing.
  -- Keep this BEFORE the match loop; don't move it inside the title check.
  tell application appName to activate
  tell application "System Events"
    tell process procName
      set frontmost to true
      -- Raise the specific matching window on top, if one exists.
      try
        repeat with w in windows
          if (title of w) contains needle then
            perform action "AXRaise" of w
            exit repeat
          end if
        end repeat
      end try
    end tell
  end tell
end run
APPLESCRIPT
