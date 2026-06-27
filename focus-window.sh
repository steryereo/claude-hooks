#!/usr/bin/env bash
# Focus the window a clicked notification belongs to. Invoked by
# `terminal-notifier -execute` when a notification is clicked.
#
# Usage:
#   focus-window.sh "<app-name>" "<process-name>" "<title-substring>" ["<iterm-session-id>"]
#
# app-name / process-name come from resolve-app.sh, baked in at hook time (the
# host app can't be detected on click — $TERM_PROGRAM is gone by then).
#
# Two strategies, best-first:
#   1. iTerm only: if an iTerm session id is given, ask iTerm to reveal that
#      exact session. This pinpoints the originating window even when several
#      windows share the same working directory — which (2) cannot disambiguate.
#   2. Generic: activate the app and raise the first window whose title contains
#      the needle (usually the project folder). If nothing matches, the app is
#      still brought forward — a best-effort fallback.
#
# First click triggers a one-time macOS prompt to control the app / System
# Events — approve it for this to work.

app="$1"
proc="$2"
needle="$3"
iterm_session="$4"

[ -z "$app" ] || [ -z "$proc" ] && exit 0

# Strategy 1 — iTerm native, by exact session id (handles same-dir duplicates).
if [ "$proc" = "iTerm2" ] && [ -n "$iterm_session" ]; then
  osascript - "$iterm_session" <<'APPLESCRIPT' 2>/dev/null && exit 0
on run argv
  set sid to item 1 of argv
  tell application "iTerm2"
    repeat with w in windows
      repeat with t in tabs of w
        repeat with s in sessions of t
          if (id of s) is sid then
            tell s to select
            activate
            return
          end if
        end repeat
      end repeat
    end repeat
  end tell
  error "session not found"
end run
APPLESCRIPT
  # Session not found (closed/moved) -> fall through to the generic path.
fi

# Strategy 2 — generic title match (+ unconditional activate fallback).
[ -z "$needle" ] && exit 0
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
