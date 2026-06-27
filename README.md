# Claude Code hooks

Personal [Claude Code](https://docs.claude.com/en/docs/claude-code) hook scripts —
macOS desktop notifications when Claude needs attention or finishes a turn, with
click-to-focus the right VS Code window.

## Scripts

| Script | Hook event | What it does |
| --- | --- | --- |
| `notify-stop.sh` | `Stop` | Notifies when Claude finishes responding; body shows the last line of the reply. |
| `notify-attention.sh` | `Notification` | Notifies on permission prompts / idle waits. |
| `window-focused.sh` | — | Helper: returns 0 if you're already looking at this session's VS Code window (caller then suppresses the notification). |
| `focus-window.sh` | — | Helper: invoked when a notification is clicked, raises the matching VS Code window. |

Scripts self-resolve their own directory, so the repo works wherever it's cloned.

## Dependencies

- [`terminal-notifier`](https://github.com/julienXX/terminal-notifier) — `brew install terminal-notifier`
- [`jq`](https://jqlang.github.io/jq/) — `brew install jq`
- macOS + VS Code (the focus logic targets the "Code" process)

First time a notification is clicked, macOS prompts to let `terminal-notifier`
control VS Code / System Events — approve it for click-to-focus to work.

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
