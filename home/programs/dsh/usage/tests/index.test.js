import assert from 'node:assert/strict';
import { afterEach, beforeEach, describe, it } from 'node:test';

import {
  DEFAULTS,
  age,
  apply,
  createBalanceClient,
  createMeter,
  formatStatusLine,
  inject,
  money,
  name,
  resolveConfig,
} from '../src/index.js';

const BODY = {
  is_available: true,
  balance_infos: [
    { currency: 'USD', total_balance: '4.65', granted_balance: '0.00', topped_up_balance: '4.65' },
  ],
};

const OK = { ok: true, balance: { total: 4.65, currency: 'USD', available: true } };

/** A balance client that replays a queued script; the last entry repeats. */
function fakeClient(...results) {
  const queue = [...results];
  let calls = 0;
  return {
    calls: () => calls,
    async fetchBalance() {
      calls += 1;
      return queue.length > 1 ? queue.shift() : queue[0];
    },
  };
}

describe('identity', () => {
  it('declares the row id the patch inserts', () => {
    assert.equal(name, 'dsh-usage');
  });
});

// ---------------------------------------------------------------- config

describe('config', () => {
  it('needs no configuration at all', () => {
    const config = resolveConfig(undefined, {});
    assert.equal(config.apiKeyEnv, 'DEEPSEEK_API_KEY');
    assert.equal(config.baseUrl, DEFAULTS.baseUrl);
    assert.equal(config.statusKey, 'deepseek-usage');
    assert.equal(config.refreshMs, 5 * 60_000);
    assert.equal(config.timeoutMs, 10_000);
  });

  it('survives a config that is not an object', () => {
    for (const raw of [null, 'x', 42, []]) {
      assert.equal(resolveConfig(raw, {}).statusKey, 'deepseek-usage');
    }
  });

  it('reads the key from the named environment variable', () => {
    assert.equal(resolveConfig({}, { DEEPSEEK_API_KEY: 'sk-live' }).apiKey, 'sk-live');
    assert.equal(
      resolveConfig({ apiKeyEnv: 'MY_KEY' }, { MY_KEY: 'sk-other', DEEPSEEK_API_KEY: 'sk-live' }).apiKey,
      'sk-other',
    );
  });

  it('lets an explicit key win over the environment', () => {
    assert.equal(resolveConfig({ apiKey: 'sk-inline' }, { DEEPSEEK_API_KEY: 'sk-live' }).apiKey, 'sk-inline');
  });

  it('is undefined, not empty, when nothing is set', () => {
    assert.equal(resolveConfig({}, {}).apiKey, undefined);
    assert.equal(resolveConfig({}, { DEEPSEEK_API_KEY: '   ' }).apiKey, undefined);
  });

  it('clamps rather than rejecting an out-of-range interval', () => {
    assert.equal(resolveConfig({ refreshMinutes: 0 }, {}).refreshMs, 60_000);
    assert.equal(resolveConfig({ refreshMinutes: 99999 }, {}).refreshMs, 24 * 60 * 60_000);
    assert.equal(resolveConfig({ timeoutSeconds: 'soon' }, {}).timeoutMs, 10_000);
  });
});

// --------------------------------------------------------------- balance

describe('balance client', () => {
  it('parses the documented response', async () => {
    const client = createBalanceClient({
      apiKey: 'sk-test',
      fetchImpl: async () => ({ ok: true, status: 200, json: async () => BODY }),
    });
    const result = await client.fetchBalance();
    assert.equal(result.ok, true);
    assert.equal(result.balance.total, 4.65);
    assert.equal(result.balance.currency, 'USD');
    assert.equal(result.balance.available, true);
  });

  it('sends the credential as a bearer token to the documented path', async () => {
    let seen;
    const client = createBalanceClient({
      apiKey: 'sk-test',
      fetchImpl: async (url, init) => {
        seen = { url, init };
        return { ok: true, status: 200, json: async () => BODY };
      },
    });
    await client.fetchBalance();
    assert.equal(seen.url, 'https://api.deepseek.com/user/balance');
    assert.equal(seen.init.headers.Authorization, 'Bearer sk-test');
  });

  it('does not double a slash on a base URL with a trailing one', () => {
    assert.equal(
      createBalanceClient({ apiKey: 'sk-test', baseUrl: 'https://api.deepseek.com/' }).endpoint,
      'https://api.deepseek.com/user/balance',
    );
  });

  it('falls back to the only entry when the currency does not match', async () => {
    const client = createBalanceClient({
      apiKey: 'sk-test',
      currency: 'USD',
      fetchImpl: async () => ({
        ok: true,
        status: 200,
        json: async () => ({ is_available: true, balance_infos: [{ currency: 'CNY', total_balance: '31.40' }] }),
      }),
    });
    const result = await client.fetchBalance();
    assert.equal(result.balance.currency, 'CNY');
  });

  it('reports a missing key rather than calling out', async () => {
    let called = false;
    const client = createBalanceClient({ fetchImpl: async () => { called = true; } });
    const result = await client.fetchBalance();
    assert.equal(result.ok, false);
    assert.match(result.error, /no API key/);
    assert.equal(called, false);
  });

  it('reports an HTTP failure without throwing', async () => {
    const client = createBalanceClient({ apiKey: 'sk-test', fetchImpl: async () => ({ ok: false, status: 401 }) });
    assert.deepEqual(await client.fetchBalance(), { ok: false, error: 'HTTP 401' });
  });

  it('reports a response carrying no usable balance', async () => {
    const client = createBalanceClient({
      apiKey: 'sk-test',
      fetchImpl: async () => ({ ok: true, status: 200, json: async () => ({ balance_infos: [] }) }),
    });
    assert.match((await client.fetchBalance()).error, /no usable balance/);
  });

  it('gives up on a fetch that ignores the abort signal', async () => {
    const client = createBalanceClient({
      apiKey: 'sk-test',
      timeoutMs: 20,
      fetchImpl: () => new Promise(() => {}),
    });
    const result = await client.fetchBalance();
    assert.equal(result.ok, false);
    assert.match(result.error, /timed out/);
  });

  it('never puts the credential into an error string', async () => {
    const client = createBalanceClient({
      apiKey: 'sk-abcdef0123456789',
      fetchImpl: async () => { throw new Error('failed for key sk-abcdef0123456789'); },
    });
    const result = await client.fetchBalance();
    assert.doesNotMatch(result.error, /abcdef/);
    assert.match(result.error, /\*\*\*/);
  });

  it('redacts anything else shaped like a key too', async () => {
    const client = createBalanceClient({
      apiKey: 'sk-mine0123456789',
      fetchImpl: async () => { throw new Error('proxy rejected sk-someoneelses9876'); },
    });
    assert.doesNotMatch((await client.fetchBalance()).error, /someoneelses/);
  });
});

// ------------------------------------------------------------- rendering

describe('money', () => {
  it('renders two decimals, the precision the endpoint reports', () => {
    assert.equal(money(4.65), '$4.65');
    assert.equal(money(0), '$0.00');
    assert.equal(money(12.5), '$12.50');
  });

  it('groups thousands without disturbing the decimals', () => {
    assert.equal(money(1234.5), '$1,234.50');
    assert.equal(money(1_234_567.89), '$1,234,567.89');
    assert.equal(money(100), '$100.00');
  });

  it('names a non-USD currency instead of faking a symbol', () => {
    assert.equal(money(31.4, 'CNY'), '31.40 CNY');
  });

  it('has a placeholder for an absent figure', () => {
    assert.equal(money(undefined), '—');
    assert.equal(money(Number.NaN), '—');
  });
});

describe('age', () => {
  it('reads "now" under a minute, since the tick is minute-grained', () => {
    assert.equal(age(0), 'now');
    assert.equal(age(59_000), 'now');
  });

  it('steps up through the units', () => {
    assert.equal(age(60_000), '1m');
    assert.equal(age(130_000), '2m');
    assert.equal(age(3 * 3_600_000), '3h');
    assert.equal(age(50 * 3_600_000), '2d');
  });

  it('rejects a nonsensical age', () => {
    assert.equal(age(-1), undefined);
    assert.equal(age(Number.NaN), undefined);
  });
});

describe('status line', () => {
  const at = 1_000_000;

  it('is balance plus how long ago it was read', () => {
    assert.equal(formatStatusLine({ balance: OK.balance, balanceAt: at - 130_000 }, at), 'bal:$4.65 (2m)');
  });

  it('reads "now" right after a poll', () => {
    assert.equal(formatStatusLine({ balance: OK.balance, balanceAt: at }, at), 'bal:$4.65 (now)');
  });

  it('lets the age carry the staleness rather than adding a marker', () => {
    // A failing refresh keeps the last good figure; the age outgrowing the
    // poll interval is the signal that something is wrong.
    const stale = { balance: OK.balance, balanceAt: at - 20 * 60_000, balanceError: 'HTTP 503' };
    assert.equal(formatStatusLine(stale, at), 'bal:$4.65 (20m)');
  });

  it('says so when the balance has never been readable', () => {
    assert.equal(formatStatusLine({ balanceError: 'no API key configured' }, at), 'bal:—');
  });

  it('stays empty before the first read rather than showing a bare label', () => {
    assert.equal(formatStatusLine({}, at), '');
    assert.equal(formatStatusLine(undefined, at), '');
  });

  it('never contains a newline, which the TUI would collapse anyway', () => {
    assert.doesNotMatch(formatStatusLine({ balance: OK.balance, balanceAt: at }, at), /\n/);
  });
});

// ----------------------------------------------------------------- meter

describe('meter', () => {
  it('keeps the last good figure when a refresh fails', async () => {
    const client = fakeClient(OK, { ok: false, error: 'HTTP 503' });
    const meter = createMeter({ balanceClient: client });

    await meter.refresh();
    await meter.refresh();

    const snapshot = meter.snapshot();
    assert.equal(snapshot.balance.total, 4.65, 'a failed poll must not blank a known balance');
    assert.equal(snapshot.balanceError, 'HTTP 503');
  });

  it('does not advance the read time on a failure, so the age keeps growing', async () => {
    let clock = 1000;
    const client = fakeClient(OK, { ok: false, error: 'HTTP 503' });
    const meter = createMeter({ balanceClient: client, now: () => clock });

    await meter.refresh();
    const first = meter.snapshot().balanceAt;

    clock += 600_000;
    await meter.refresh();
    assert.equal(meter.snapshot().balanceAt, first);
  });

  it('clears the error once a refresh succeeds again', async () => {
    const meter = createMeter({ balanceClient: fakeClient({ ok: false, error: 'HTTP 503' }, OK) });
    await meter.refresh();
    await meter.refresh();
    assert.equal(meter.snapshot().balanceError, undefined);
  });

  it('coalesces concurrent refreshes into one request', async () => {
    const client = fakeClient(OK);
    const meter = createMeter({ balanceClient: client });
    await Promise.all([meter.refresh(), meter.refresh(), meter.refresh()]);
    assert.equal(client.calls(), 1);
  });

  it('never rejects, even if the client breaks its contract and throws', async () => {
    const errors = [];
    const meter = createMeter({
      onError: (error) => errors.push(error),
      balanceClient: { async fetchBalance() { throw new Error('boom'); } },
    });
    await assert.doesNotReject(meter.refresh());
    assert.equal(meter.snapshot().balance, undefined);
    assert.equal(errors.length, 1);
  });

  it('lets one broken listener not stop the others', async () => {
    const errors = [];
    let reached = false;
    const meter = createMeter({ balanceClient: fakeClient(OK), onError: (e) => errors.push(e) });
    meter.onChange(() => { throw new Error('bad listener'); });
    meter.onChange(() => { reached = true; });

    await meter.refresh();
    assert.equal(reached, true);
    assert.equal(errors.length, 1);
  });

  it('stops notifying once unsubscribed', async () => {
    let count = 0;
    const meter = createMeter({ balanceClient: fakeClient(OK) });
    const off = meter.onChange(() => { count += 1; });
    await meter.refresh();
    off();
    await meter.refresh();
    assert.equal(count, 1);
  });
});

describe('the tick', () => {
  /** Drive the interval by hand so the cadence is asserted, not waited for. */
  function harness({ refreshMs = 5 * 60_000 } = {}) {
    let clock = 0;
    let fire;
    const client = fakeClient(OK);
    const meter = createMeter({
      balanceClient: client,
      refreshMs,
      now: () => clock,
      setTimer: (fn) => { fire = fn; return 'handle'; },
      clearTimer: () => { fire = undefined; },
    });
    return {
      meter,
      client,
      advance: (ms) => { clock += ms; },
      tick: () => fire?.(),
      stopped: () => fire === undefined,
    };
  }

  it('polls immediately on start rather than waiting out an interval', async () => {
    const h = harness();
    h.meter.start();
    await Promise.resolve();
    assert.equal(h.client.calls(), 1);
  });

  it('repaints every tick so the age advances between polls', async () => {
    const h = harness();
    let paints = 0;
    h.meter.onChange(() => { paints += 1; });

    h.meter.start();
    await Promise.resolve();
    assert.equal(paints, 1, 'the initial poll paints');

    h.advance(60_000);
    h.tick();
    await Promise.resolve();
    assert.equal(h.client.calls(), 1, 'a minute is not yet due for a poll');
    assert.equal(paints, 2, 'but the line must repaint so "(1m)" appears');
  });

  it('polls again once the refresh interval has elapsed', async () => {
    const h = harness({ refreshMs: 5 * 60_000 });
    h.meter.start();
    await Promise.resolve();

    for (let minute = 0; minute < 4; minute += 1) {
      h.advance(60_000);
      h.tick();
      await Promise.resolve();
    }
    assert.equal(h.client.calls(), 1);

    h.advance(60_000);
    h.tick();
    await Promise.resolve();
    assert.equal(h.client.calls(), 2);
  });

  it('is idempotent on start and stop', () => {
    const h = harness();
    h.meter.start();
    h.meter.start();
    h.meter.stop();
    assert.equal(h.stopped(), true);
    h.meter.stop();
  });
});

// ---------------------------------------------------------------- wiring

function fakeTuiStatus() {
  const entries = new Map();
  let token = 0;
  return {
    entries,
    set(key, text) {
      const mine = (token += 1);
      entries.set(key, { text, token: mine });
      return () => {
        if (entries.get(key)?.token === mine) entries.delete(key);
      };
    },
  };
}

/**
 * A host mirroring Cordis's injection contract: because the row declares
 * `inject: ['tuiStatus']`, Cordis defers apply until the service is live and
 * exposes it as a property on ctx. Reaching for it any later is what broke
 * the real TUI, so the fake deliberately offers no other way to get it.
 */
function fakeContext({ tuiStatus = fakeTuiStatus() } = {}) {
  const warnings = [];
  return {
    tuiStatus,
    warnings,
    ctx: {
      tuiStatus,
      logger: { warn: (message) => warnings.push(message) },
    },
  };
}

describe('plugin', () => {
  let realFetch;

  beforeEach(() => {
    realFetch = globalThis.fetch;
    globalThis.fetch = async () => ({ ok: true, status: 200, json: async () => BODY });
  });

  afterEach(() => {
    globalThis.fetch = realFetch;
  });

  const settle = () => new Promise((resolve) => setImmediate(resolve));

  it('requires tuiStatus rather than probing for it', () => {
    // Regression guard. Without this the row activates before the
    // dsh-tui-extensions row provides tuiStatus; dsh-tui's caller guard then
    // rejects every set() as a stale activation and returns a no-op, so the
    // status line silently never renders and the only warning goes to a
    // logger the TUI discards.
    assert.deepEqual(inject, ['tuiStatus']);
  });

  it('paints synchronously during apply, before any balance has arrived', async () => {
    // The in-apply paint is the one dsh-tui's guard accepts, so it must not
    // be deferred to the first refresh.
    const host = fakeContext();
    const dispose = await apply(host.ctx, { apiKey: 'sk-test' });

    assert.equal(host.tuiStatus.entries.has('deepseek-usage'), true);
    dispose();
  });

  it('repaints with the balance once it arrives', async () => {
    const host = fakeContext();
    const dispose = await apply(host.ctx, { apiKey: 'sk-test' });
    await settle();

    assert.equal(host.tuiStatus.entries.get('deepseek-usage').text, 'bal:$4.65 (now)');
    dispose();
  });

  it('honours a renamed status key', async () => {
    const host = fakeContext();
    const dispose = await apply(host.ctx, { apiKey: 'sk-test', statusKey: 'ds' });
    await settle();

    assert.ok(host.tuiStatus.entries.has('ds'));
    dispose();
  });

  it('registers no slash command, since the TUI can only toast one line', async () => {
    let registered = false;
    const host = fakeContext();
    host.ctx.commands = { register() { registered = true; return () => {}; } };
    const dispose = await apply(host.ctx, { apiKey: 'sk-test' });
    await settle();

    assert.equal(registered, false);
    dispose();
  });

  it('leaves exactly one status entry after many repaints', async () => {
    const host = fakeContext();
    const dispose = await apply(host.ctx, { apiKey: 'sk-test' });
    for (let i = 0; i < 20; i += 1) await settle();

    assert.equal(host.tuiStatus.entries.size, 1);
    dispose();
  });

  it('leaves no orphan status line behind', async () => {
    const host = fakeContext();
    const dispose = await apply(host.ctx, { apiKey: 'sk-test' });
    await settle();

    dispose();
    assert.equal(host.tuiStatus.entries.size, 0, 'status entry outlived the row');
  });

  it('is idempotent on teardown', async () => {
    const host = fakeContext();
    const dispose = await apply(host.ctx, { apiKey: 'sk-test' });
    await settle();

    dispose();
    assert.doesNotThrow(dispose);
    assert.equal(host.tuiStatus.entries.size, 0);
  });

  it('reports a broken disposer instead of abandoning teardown', async () => {
    const tuiStatus = fakeTuiStatus();
    tuiStatus.set = () => () => { throw new Error('clear exploded'); };
    const host = fakeContext({ tuiStatus });
    const dispose = await apply(host.ctx, { apiKey: 'sk-test' });
    await settle();

    assert.doesNotThrow(dispose);
    assert.equal(host.warnings.length, 1);
  });

  it('loads and shows the absence when there is no API key', async () => {
    const host = fakeContext();
    // Point at a variable that certainly is not set: `apply` reads the real
    // process.env, and the developer's own key is exported in any shell the
    // dsh wrapper has touched.
    const dispose = await apply(host.ctx, { apiKeyEnv: 'DSH_USAGE_ABSENT_KEY' });
    await settle();

    assert.equal(host.tuiStatus.entries.get('deepseek-usage').text, 'bal:—');
    dispose();
  });

  it('tolerates a config that is not an object', async () => {
    const host = fakeContext();
    const dispose = await apply(host.ctx, null);
    await settle();
    assert.doesNotThrow(dispose);
  });
});
