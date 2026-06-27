# Claude Code hooks

Personal [Claude Code](https://docs.claude.com/en/docs/claude-code) hook scripts

- fire a macOS desktop notification when Claude needs attention or finishes a turn
- switch to the window that needs attention when the notification is clicked

## Scripts

| Script | Hook event | What it does |
| --- | --- | --- |
| `notify-stop.sh` | `Stop` | Notifies when Claude finishes responding; body shows the last line of the reply. |
| `notify-attention.sh` | `Notification` | Notifies on permission prompts / idle waits. |
| `focus-window.sh` | — | Helper: invoked when a notification is clicked, raises the matching host-app window. |
| `resolve-app.sh` | — | Helper: maps `$TERM_PROGRAM` to the macOS app/process names of the host terminal/IDE. |
| `window-focused.sh` | — | Helper: returns 0 if you're already looking at this session's window (caller then suppresses the notification). |


Scripts self-resolve their own directory, so the repo works wherever it's cloned.

## Supported host apps

The focus / suppression logic detects the host app from `$TERM_PROGRAM` (resolved at hook time, since it isn't available in the click callback). Out of the box: **VS Code**, **iTerm2**, and **Terminal.app**. Other apps still get notifications — only click-to-focus and the "already focused" suppression are skipped.

Click-to-focus uses, in order
1. on **iTerm2**, the originating session via `$ITERM_SESSION_ID` (captured at hook time) — pinpoints the right window even with several windows on the same directory.
2. otherwise, raising the first window whose title contains an identifying segment of the session path (e.g. the project folder) — works for VS Code by default; (3) if neither matches, the host app is still brought forward (just not a specific window).

**iTerm2 note:** both click-to-focus and the suppression check are precise out of the box, no setup. They both key off `$ITERM_SESSION_ID` (captured at hook time): the click reveals that exact session, and `window-focused.sh` asks iTerm for the currently-focused session and suppresses only when it's this one. That distinguishes the right tab/split-pane even when several share a working directory — title matching (used for other hosts) can't. If iTerm isn't the frontmost app, or the focused session is a different one, the notification is sent.

## Dependencies

- [`terminal-notifier`](https://github.com/julienXX/terminal-notifier) — `brew install terminal-notifier`
- [`jq`](https://jqlang.github.io/jq/) — `brew install jq`
- macOS (the focus logic drives the host app via AppleScript / System Events)

First time a notification is clicked, macOS prompts to let `terminal-notifier` control the host app / System Events — approve it for click-to-focus to work.

## Install

Clone into `~/.claude/hooks` (or clone elsewhere and point the config at it):

```sh
git clone <repo-url> ~/.claude/hooks
chmod +x ~/.claude/hooks/*.sh
```

Then wire them up in `~/.claude/settings.json`

```json
{
  "hooks": {
    "Stop": [
      { "hooks": [{ "type": "command", "command": "$HOME/.claude/hooks/notify-stop.sh" }] }
    ],
    "Notification": [
      { "hooks": [{ "type": "command", "command": "$HOME/.claude/hooks/notify-attention.sh" }] }
    ]
  }
}
```
