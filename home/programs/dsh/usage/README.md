# @oxey/dsh-usage

The DeepSeek credit balance, in the TUI status line.

```
bal:$4.65 (2m)
```

That is the whole plugin: the balance, and how long ago it was read.

## Why it is only this

The TUI already renders tokens, cache hit rate and context occupancy from its
own `dsh-token-meter`, and ships a `/tokens` command. Its status-line defaults
are:

```js
contextUsage: true,  cache: true,
tokens: false,       tps: false,  contextBar: false,
```

So the cache hit rate is already on screen, and token counts, a TPS meter and
a segmented context bar are one setting each. Reimplementing any of that here
would duplicate it.

The one thing nothing in the harness does is ask the account how much credit
is left — that is an HTTP call to `GET /user/balance`, not anything derivable
from the session log. That gap is what this fills.

## Why the age is shown

It is the staleness signal. A failed refresh keeps the last known figure —
still the best answer available — while the age visibly outgrows the poll
interval, so there is no separate error marker to decode. The plugin's single
timer ticks every minute to advance it and polls when the refresh interval is
due; without that repaint the age would only ever read `now`.

`bal:—` means the balance has never been readable at all (usually a missing
or rejected key).

## Why there is no slash command

Plugin-registered commands reach the TUI through `channel.notify()`, and that
text is whitespace-collapsed to a single line, capped at 200 cells and drawn
in the narrow footer slot — a multi-line report cannot render through that
seam, and a one-line one would only repeat the status line.

## Why there is no cost figure

`/user/balance` reports whole cents (`"4.65"`) and a session routinely costs a
fraction of one, so a spend figure derived from balance deltas would read
`$0.00` almost always. The alternative is hard-coding DeepSeek's peak and
off-peak rate tables plus their UTC windows and pricing every call locally —
a pile of assumptions that goes quietly wrong whenever DeepSeek changes
anything. The balance is exact, and it is the number that answers "can I keep
going".

## Why it injects `tuiStatus`

It has to, and getting this wrong produces a plugin that loads cleanly and
renders nothing.

Rows load concurrently, so this one can activate before the
`dsh-tui-extensions` row has provided `tuiStatus`. Picking the service up
afterwards — from an `internal/service` listener — looks like it works: the
service is there, `set` is called, no error is thrown. But `tuiStatus.set`
runs `requirePluginCaller`, which walks dsh-tui's canonical fiber maps, and a
row that activated before the service existed fails that check with `mutated
runner`. Every `set` then returns a silent no-op, and the only warning goes to
a logger the TUI discards.

Declaring `inject: ['tuiStatus']` makes Cordis defer this row until the
service is live, so the first paint lands inside a clean activation and later
repaints are accepted too. Under headless/web the row stays PENDING, which is
correct: it has nothing to contribute there.

## Configuration

Every field is optional. Set them on the `dsh-usage` row in a profile patch:

```yaml
- id: dsh-usage
  config:
    apiKeyEnv: DEEPSEEK_API_KEY   # variable holding the key
    baseUrl: https://api.deepseek.com
    currency: USD                 # which balance_infos entry to prefer
    refreshMinutes: 5             # balance poll interval
    timeoutSeconds: 10
    statusKey: deepseek-usage     # status-line key this plugin owns
```

A bad value falls back to its default rather than failing the row: a broken
balance indicator must never stop the harness from booting.

Prefer `apiKeyEnv` over an inline `apiKey` — a profile patch is world-readable
in `/nix/store`.

## State

None. Nothing is written to disk.

## Development

```sh
node --test "tests/*.test.js"
```

One source file, no dependencies, no build step: plain ESM, run as-is.
