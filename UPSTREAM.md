# Local branch: what it carries

`local` = RoversX/apple_reminder_cli `0.1.3` (`main` @ 6173377) + openclaw/remindctl `v0.3.9`
merged (history kept) + the work below (docs/development-model.md in eejd/macports-ports-local,
"Forks, upstreams and port tiers"). `main` mirrors RoversX `main`; `track/openclaw/main` mirrors
openclaw `main`.

| Branch/commit | What | Upstream status |
|---|---|---|
| merge of `openclaw/remindctl@1ae0c5dbc607c9c682b0f8d895c7138de603e615` (`v0.3.9`) | About 20 bug fixes and the new command set: `search`, `info`, `export`, `link`, `open`, `doctor`, `completion`, alarms, recurrence, URL read/write, location triggers, `--list-id`, table output, strict Commander 0.3.0 validation. RoversX naming, identity (bundle id, version, Info.plist) and policy layer win on conflict; openclaw CI, release, Homebrew and docs-site files are dropped. | not submitted to RoversX |
| `local: apply apple_reminder_cli naming to merged remindctl code` | Renames `remindctl` to `apple_reminder_cli` in merged Sources/Tests. Kept on purpose: the `REMINDCTL_VERSION` env fallback and the `remindctl URL (managed)` note marker (data format shared with remindctl-written reminders). | local only |
| `local: reconcile tests after remindctl v0.3.9 merge` | Compile and test fixes where openclaw code met the policy layer (`.table` output cases for policy commands, edit/add hook adaptation). | local only |
| `feature/policy-coverage` | Extends the per-list policy to `search`, `info`, `export`, `link`, `open`, `edit` moves and alarm/recurrence/URL edits, with `--list-id` and loosely spelled `--list` names resolved to the real list title first. README "Policy coverage". | local only |
