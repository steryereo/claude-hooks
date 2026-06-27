# Claude Code hooks

Personal [Claude Code](https://docs.claude.com/en/docs/claude-code) hook scripts

- fire a macOS desktop notification when Claude needs attention or finishes a turn
- switch to the window that needs attention when the notification is clicked

## Scripts

| Script | Hook event | What it does |
| --- | --- | --- |
| `notify-stop.sh` | `Stop` | Notifies when Claude finishes responding; body shows the last line of the reply. |
| `notify-attention.sh` | `Notification` | Notifies on permission prompts / idle waits. |
| `resolve-app.sh` | — | Helper: maps `$TERM_PROGRAM` to the macOS app/process names of the host terminal/IDE. |
| `focus-window.sh` | — | Helper: invoked when a notification is clicked, raises the matching host-app window. |
| `window-focused.sh` | — | Helper: returns 0 if you're already looking at this session's window (caller then suppresses the notification). |


Scripts self-resolve their own directory, so the repo works wherever it's cloned.

## Supported host apps

The focus / suppression logic detects the host app from `$TERM_PROGRAM` (resolved
at hook time, since it isn't available in the click callback). Out of the box:
**VS Code**, **iTerm2**, and **Terminal.app**. Other apps still get notifications
— only click-to-focus and the "already focused" suppression are skipped. Add more
in `resolve-app.sh`.

Click-to-focus relies on the host app putting an identifying segment of the
session path (e.g. the project folder) in its window title — true for VS Code by
default; terminals depend on profile/title settings.

## Dependencies

- [`terminal-notifier`](https://github.com/julienXX/terminal-notifier) — `brew install terminal-notifier`
- [`jq`](https://jqlang.github.io/jq/) — `brew install jq`
- macOS (the focus logic drives the host app via AppleScript / System Events)

First time a notification is clicked, macOS prompts to let `terminal-notifier`
control the host app / System Events — approve it for click-to-focus to work.

## Install

Clone into `~/.claude/hooks` (or clone elsewhere and point the config at it):

```sh
git clone <repo-url> ~/.claude/hooks
chmod +x ~/.claude/hooks/*.sh
```

Then wire them up in `~/.claude/settings.json` (this part is NOT committed here —
`settings.json` holds personal permissions/secrets and should stay out of git):

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
