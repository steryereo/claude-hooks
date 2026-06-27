#!/usr/bin/env bash
# Focus the VS Code window whose title contains the given substring (the project
# folder name). Invoked by `terminal-notifier -execute` when a notification is
# clicked. VS Code's default window title includes the workspace folder name,
# so matching on the project basename lands on the right window.
#
# Usage: focus-window.sh "<title-substring>"
#
# First click triggers a one-time macOS prompt: "terminal-notifier wants to
# control Visual Studio Code / System Events" — approve it for this to work.

needle="$1"

osascript - "$needle" <<'APPLESCRIPT' 2>/dev/null
on run argv
  set needle to item 1 of argv
  tell application "Visual Studio Code" to activate
  tell application "System Events"
    tell process "Code"
      set frontmost to true
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
