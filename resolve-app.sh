#!/usr/bin/env bash
# Resolve the host terminal/IDE that a Claude Code session is running in, so the
# focus/suppression logic isn't hardcoded to one app.
#
# Reads $TERM_PROGRAM (set by the terminal and inherited by hook subprocesses),
# or an explicit override as $1. Prints "AppName|ProcessName" and exits 0 on a
# known app, or prints nothing and exits 1 on an unknown/unset one.
#
# Two names are emitted because they differ for some apps:
#   - AppName     -> used by AppleScript `tell application "<App>" to activate`
#   - ProcessName -> used by System Events `tell process "<Process>"`
#
# NOTE: must be resolved at HOOK time. terminal-notifier's -execute callback runs
# in a different environment where $TERM_PROGRAM is gone, so callers bake the
# resolved names into the click command rather than re-resolving on click.
#
# Caveat: VS Code forks (e.g. Cursor) also report TERM_PROGRAM=vscode but run as
# a different app/process, so they'd be mis-targeted here. Add cases as needed.

term="${1:-$TERM_PROGRAM}"

case "$term" in
  vscode)         echo "Visual Studio Code|Code" ;;
  iTerm.app)      echo "iTerm|iTerm2" ;;
  Apple_Terminal) echo "Terminal|Terminal" ;;
  *)              exit 1 ;;
esac
