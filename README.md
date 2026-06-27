# Claude Code hooks

[Claude Code](https://docs.claude.com/en/docs/claude-code) hook scripts

- fire a macOS desktop notification when Claude needs attention or finishes a turn
- switch to the window that needs attention when the notification is clicked

## Scripts

| Script | Hook event | What it does |
| --- | --- | --- |
| `notify-stop.sh` | `Stop` | Notifies when Claude finishes responding. Body shows the last line of the reply. |
| `notify-attention.sh` | `Notification` | Notifies on permission prompts / idle waits. |
| `focus-window.sh` | — | Helper: invoked when a notification is clicked, raises the matching host-app window. |
| `resolve-app.sh` | — | Helper: maps `$TERM_PROGRAM` to the macOS app/process names of the host terminal/IDE. |
| `window-focused.sh` | — | Helper: checks if you're already looking at this session's window (caller then suppresses the notification). |


## Supported host apps

The focus / suppression logic detects the host app from `$TERM_PROGRAM`. Out of the box: **VS Code**, **iTerm2**, and **Terminal.app**. Other apps still get notifications — only click-to-focus and the "already focused" suppression are skipped.

Click-to-focus uses, in order
1. on **iTerm2**, the originating session via `$ITERM_SESSION_ID` — pinpoints the window and tab that the notification originates from.
2. otherwise, raising the first window whose title contains an identifying segment of the session path (e.g. the project folder). This works for VS Code by default. Other programs might require configuration to include current working directory in the window title
3. if neither matches, the host app is still brought forward, just not a specific window or tab.


## Dependencies

- [`terminal-notifier`](https://github.com/julienXX/terminal-notifier)
  - posts the macOS desktop notification and runs the click-to-focus callback.
  - To install: `brew install terminal-notifier`
- [`jq`](https://jqlang.github.io/jq/)
  - parses the hook JSON payload on stdin.
  - To install: `brew install jq`
- macOS
  — the focus logic uses AppleScript / System Events.

## Install

This repo is both a Claude Code plugin and a single-plugin marketplace. Install the dependencies above first, then run the following:

```sh
/plugin marketplace add steryereo/claude-hooks
/plugin install claude-hooks@steryereo
```

This registers the `Stop` and `Notification` hooks automatically. To install from a local clone instead of GitHub, point the marketplace at the clone: `/plugin marketplace add ~/path/to/claude-hooks`.

Note: macOS asks for AppleScript automation permission twice — once per path, the first time each runs:

- **Hook time** — the host app (iTerm2, etc.) prompts to control System Events / iTerm2 for the suppression check. Decline or ignore it and suppression just fails safe: the notification is still sent.
- **Click time** — `terminal-notifier` prompts to control the host app / System Events for click-to-focus. Approve it, or clicking a notification won't focus the window.
