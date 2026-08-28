# My Agents

One bar icon and one panel for every AI coding subscription on the machine.
The panel is strictly a display: it watches the usage records that
`omarchy-agent-usage-update` writes to `~/.local/state/omarchy/agents/usage/`
and draws whatever appears there. `Panel.qml` owns the bar button and the
popup; `Main.qml` discovers and watches the records (and handles the optional
cross-device aggregation); `Agent.qml` is the per-record file watcher.

## Install

```bash
omarchy plugin add https://github.com/Ch3w3y/omarchy-agents.git --enable
```

Then run the bundled installer, which copies every collector in `scripts/`
to `~/.local/bin` (no `sudo`/`pkexec`, no package manager calls, nothing
written outside `$HOME`):

```bash
~/.config/omarchy/plugins/daryn.agents/install.sh
```

Claude, Codex, Fireworks, Antigravity, and Pi need nothing beyond a
signed-in CLI or local session data to already exist. OpenRouter, OpenCode
Go, and Ollama Cloud take an API key from the panel's own gear icon; Nous
Portal signs in from the same place (or `omarchy-agent-nous-login`
directly) since it has no plain key to paste. See "API keys" below.

## Panel

- **Hero** — the mark, the tool, and the plan it runs on ("Max 20x", "Pro").
  Auth and endpoint problems replace the plan line and repeat in a card.
- **Subscription switch** — one chip per enabled agent (`h`/`l` or click).
  It appears only when more than one agent is enabled.
- **Limits** — the percentage of each allowance used, a matching meter, and
  the time until the session or weekly window resets.
- **Balance** — prepaid agents report a credit ledger instead of limits:
  remaining credit, a fuel-gauge meter that drains toward empty, and
  funded-versus-spent detail.
- **Tokens by day** — one row per day for the last week: day, bar, tokens, with today
  bolded at the bottom. Hover today for its prompt and session count.
- **Tokens by model** — tokens per model with the bar behind each row scaled
  to the heaviest model,
  the same way the weekly chart scales to its busiest day. Hover for the
  input / output / cache split.
- **Gear icon** — the hero's trailing control swaps the dashboard for a
  settings screen: a key field per provider with no signed-in CLI of its own
  (OpenRouter, OpenCode Go, Ollama Cloud), and a sign-in button for Nous
  Portal, which is OAuth-only. See "API keys" below.

A subscription appears only when it is enabled in settings and has actually
recorded usage — on this machine or on a synced one. With one such agent
there is no switch row at all; with none, the module leaves the bar entirely
rather than sitting there with nothing to say. A CLI installed mid-session
shows up at the next refresh, so nothing polls the disk waiting for it.

That self-hiding is why the widget ships in the default bar layout: a machine
that has never run an AI coding agent draws nothing, and the icon arrives on
its own the first time a scan finds usage. Drop it with
`omarchy plugin disable daryn.agents`.

## Data

Each agent is one JSON record in `~/.local/state/omarchy/agents/usage/`,
written by `omarchy-agent-usage-update`. That command runs one
`omarchy-agent-usage-<agent>` collector per agent; the widget invokes it
on its refresh timer and whenever you ask for a refresh, and picks up any
record that lands in the directory regardless of who wrote it.

Adding an agent therefore never touches this plugin: ship a collector that
prints the record contract (see the `claude` and `codex` collectors in
`bin/`), and the panel gains a tab. An `assets/<id>.svg` mark is optional —
with an `assets/<id>-light.svg` twin if the mark needs a dark variant for
light surfaces — and, with neither, the provider switch falls back to a
couple of letters from its name rather than stealing width from every other
chip; the hero falls back to the module's own bar glyph. `openrouter.svg`,
`opencode-go.svg`, `ollama-cloud(-light).svg`, and `nous(-light).svg` are
each provider's real official mark, sourced from its own domain (its
favicon, or in Nous's case the vector mask icon nousresearch.com ships for
Safari's pinned tabs, recolored per surface). Qt's SVG renderer is stricter
than a browser's — a nested `<svg>` or a `<style>` block can render blank
here even though it previews fine in a normal image viewer — so a fetched
mark needs flattening to one clean top-level `<svg>` before it's usable.

| Collector | Limits | Local stats |
|---|---|---|
| `claude` | Anthropic's OAuth usage endpoint (5-hour session + 7-day weekly) | `~/.claude/projects` transcripts, opencode sessions on an Anthropic provider, plus `stats-cache.json` and `history.jsonl` as fallback |
| `codex` | The Codex app-server RPC | native Codex CLI session files (plus pi and opencode sessions) |
| `fireworks` | Estimated prepaid balance: configured funding minus rated account costs | Fireworks billing API, grouped by day and model for the last 30 days |
| `antigravity` | — (no metered plan) | Antigravity's native conversation databases, plus opencode/pi sessions on a Google/Gemini provider |
| `openrouter` | Prepaid balance (`/credits`) plus the API key's own cap, if one is set (`/key`) | none — OpenRouter keeps no session data of its own |
| `opencode-go` | Rolling (5-hour), weekly, and monthly usage windows from OpenCode Go's own usage endpoint | none |
| `ollama-cloud` | Session (5-hour) and weekly usage fractions from Ollama's undocumented `/api/usage` | none |
| `pi` | — (no metered plan; Pi routes to whichever provider you point it at) | `~/.pi/agent/sessions` (and the legacy `~/.omp/agent/sessions`), every provider, not just the Anthropic/OpenAI slices `claude` and `codex` already fold in under their own tabs |
| `nous` | Monthly credit usage from Nous Portal's account endpoint | none |

Claude limits need a signed-in CLI; without credentials the panel says so and
falls back to local stats only. A non-default Claude directory is honored via
`CLAUDE_CONFIG_DIR`, Codex via `CODEX_HOME`. Fireworks reads
`FIREWORKS_API_KEY` and `FIREWORKS_ACCOUNT_ID` first, then
`~/.fireworks/auth.ini` (which `firectl set-api-key` creates), then the key
opencode stores in `~/.local/share/opencode/auth.json` when Fireworks is
signed in there.

OpenRouter, OpenCode Go, Ollama Cloud, and Nous Portal have no local
transcripts to fall back on, so each tab is limits/balance only — it
disappears entirely rather than sitting empty when there is nothing to show,
same as any other agent with no data (see "Panel" above).

## API keys

The gear icon on the hero opens a settings screen with one field per
provider that has no CLI of its own to detect a sign-in from: OpenRouter,
OpenCode Go, and Ollama Cloud each take a pasted API key there. Saving
writes it through `omarchy-agent-credential-set` to
`~/.config/omarchy/agents/credentials.json` (0600 from the moment it's
created — atomic write, never a world-readable window) and immediately
re-runs that one collector so the tab updates without waiting out the
refresh timer. The field itself never shows a saved key back; "Connected" —
read from the collector's own last probe, the same status line the dashboard
shows — is the only confirmation there is. Clearing a field removes that
provider's entry from the file entirely rather than saving an empty string.

Nous Portal has no plain API key for its account endpoint — only OAuth — so
its row is a "Sign in" button instead of a field. It opens a terminal
running `omarchy-agent-nous-login`, the same RFC 8628 device-code flow
Hermes Agent and ai-usagebar use (the public `hermes-cli` client id, not a
secret): it prints a URL and a confirmation code, opens the URL, and waits.
The resulting token lands in `~/.config/omarchy/agents/nous-credentials.json`
(also 0600), which `nous` then refreshes on its own going forward.

Each collector checks in this order:

| Collector | Credential sources |
|---|---|
| `openrouter` | `OPENROUTER_API_KEY`, then the settings screen's key, then `api_key` under `[openrouter]` in `~/.config/ai-usagebar/config.toml` if [ai-usagebar](https://github.com/akitaonrails/ai-usagebar) is already configured |
| `opencode-go` | `OPENCODE_GO_API_KEY`, then the key opencode stores in `~/.local/share/opencode/auth.json` after `opencode auth login`, then the settings screen's key, then ai-usagebar's config as above |
| `ollama-cloud` | `OLLAMA_API_KEY`, then the key the `pi` CLI stores in `~/.pi/agent/auth.json`, then an `ollama`/`ollama-cloud` entry in opencode's `auth.json`, then the settings screen's key |
| `nous` | `~/.config/omarchy/agents/nous-credentials.json` (written by `omarchy-agent-nous-login`, refreshed automatically); a still-valid Nous token already sitting in ai-usagebar's `credentials.json` is imported once as a bootstrap and never read again afterward |

`nous` deliberately never shares ai-usagebar's own OAuth token beyond that
one-time import: Nous rotates the refresh token on every use, so two tools
refreshing the same one would race, and whichever refreshed second would
find its copy already revoked.

An OpenRouter account that only ever pays per request — no purchased credit
balance and no per-key cap — has nothing bounded to show a percentage or a
balance against, so its tab stays hidden even while signed in; set a cap on
the key at openrouter.ai to get a meter. Ollama Cloud's endpoint is
undocumented (there is no official one as of August 2026) and may change
shape without notice; a schema mismatch degrades to a plain "unavailable"
card rather than a crash, the same as any HTTP failure.

`pi` is a router, not an account, so its tab counts every session Pi has
ever run regardless of backend — including the same Anthropic- and
OpenAI-routed messages `claude` and `codex` already count under their own
tabs. That overlap is by design: `claude`/`codex` answer "how much of this
subscription did I use," `pi` answers "how much did I use this tool,"
and a Pi session against, say, a Google or Fireworks model only shows up
here. Nothing across tabs is double-counted toward any one limit — pi has
no limit of its own to count toward.

### Fireworks balance

The collector first asks the account's `:getBalance` endpoint for the real
prepaid ledger. That endpoint exists but is permission-gated, and as of
August 2026 no console-issued API key passes it — Fireworks appears to
reserve it for the dashboard session. The probe stays because it is cheap
and the live figure lights up automatically if Fireworks ever opens it to
keys. Until then the collector falls back to estimating the balance from
configuration in `~/.config/omarchy/agents/fireworks.json`:

```json
{
  "accountId": "",
  "fundedAmount": 20,
  "fundedAt": "2026-07-01"
}
```

Set `fundedAmount` to the credits purchased and optionally `fundedAt` to the
purchase date; with no date, the collector uses the account creation time. It
subtracts rated account costs and the panel labels the result as estimated.
For a later top-up, increase `fundedAmount` by the new credit while keeping
the original `fundedAt`, so both the funding and spend still cover the same
period. `accountId` only matters when one API key can access several
accounts. Without a configured `fundedAmount` the tab still shows token
usage, just no balance. With a live ledger, `fundedAmount` is optional and
only adds the meter and the spent-of-funded line under the real figure.

## Interactions

- Bar icon: left = panel, right = launch agent, middle = next subscription.
- Panel: `h`/`l` switch subscription, `j`/`k` scroll, `r` or Enter refresh,
  Tab moves to the neighboring bar panel, Esc closes.
- IPC: `omarchy-shell daryn.agents <open|close|toggle|refresh|next>`.

## Settings

Settings live in the widget's entry in `~/.config/omarchy/shell.json`. The
top-level keys can be set with
`omarchy bar set daryn.agents <key> <value>`:

| Key | Default | What it does |
|---|---|---|
| `refreshIntervalSec` | `900` | How often the usage records regenerate |
| `syncMode` | `"Off"` | `"On"` writes this machine's snapshot and merges the others |
| `syncDir` | `""` | A folder synced by Syncthing, Dropbox, rsync, … |
| `syncFileName` | `<hostname>.json` | This machine's snapshot file |
| `syncDeviceId` | hostname | Stable device name inside the snapshot |

Numbers need `--json`, or they land in `shell.json` as strings:

```bash
omarchy bar set daryn.agents refreshIntervalSec 300 --json
omarchy bar set daryn.agents syncDir '~/Sync/agent-usage'
```

Per-agent enablement is nested, and `set` writes its key literally rather
than walking a dotted path — so pass the whole `providers` object as JSON (or
edit `shell.json` directly):

```bash
omarchy bar set daryn.agents providers '{
  "claude": { "enabled": true },
  "codex": { "enabled": false },
  "fireworks": { "enabled": true }
}' --json
```

`enabled` defaults to `true` for every discovered agent; set it to `false` to
hide a subscription that is installed. Disabled agents are also skipped when
the records regenerate.

With `syncMode` on, every `*.json` snapshot in `syncDir` is merged, so today,
the last 7 days, and the all-time totals cover every machine you code on —
active days are unioned by date rather than summed. Rate limits stay
per-account and are never merged. A record may declare `"scope": "account"`
when its stats are account-global rather than machine-local (Fireworks'
billing API); those merge by taking the widest value instead of summing, so
the same account synced from two machines is not counted twice.

One caveat on "all-time": the Codex collector only reads native session files
touched in the last 30 days, and Fireworks requests the last 30 days from its
billing API, so their totals and day counts cover that window. Claude's cover
every transcript still on disk.
