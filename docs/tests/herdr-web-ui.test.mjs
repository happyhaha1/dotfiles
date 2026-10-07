import assert from "node:assert/strict";
import { existsSync, mkdtempSync, mkdirSync, readFileSync, rmSync, statSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { test } from "node:test";
import { loadConfig, parseEnv, reconcile, stopManaged } from "../../.chezmoitemplates/herdr-web-ui-sync.mjs";

const source = "devswha/herdr-web-ui";
const plugin = "devswha.herdr-web-ui";
const ref = "v0.3.52";
// Deliberately exercise the same characters that broke shell-sourced passwords.
const password = "mock-password & $ # \\ \" ' end";

function fixture(t, options = {}) {
    const home = mkdtempSync(join(tmpdir(), "web-ui-test-"));
    t.after(() => rmSync(home, { recursive: true, force: true }));
    const stateHome = join(home, ".local", "state");
    const envFile = join(home, ".config", "herdr", "plugins", "config", plugin, ".env");
    const ownerFile = join(stateHome, "chezmoi", "herdr-plugins");
    const stampFile = join(stateHome, "chezmoi", "herdr-web-ui");
    mkdirSync(dirname(envFile), { recursive: true });
    mkdirSync(dirname(ownerFile), { recursive: true });
    if (options.owned !== false) writeFileSync(ownerFile, `${source}\t${ref}\n`, { mode: 0o600 });
    function configure(token = password, host = "192.0.2.10") {
        writeFileSync(envFile, `HOST="${host}"\nPORT=7317\nHERDR_WEB_TOKEN="${token}"\nHERDR_WEB_AUTO_UPDATE=0\n`, { mode: 0o600 });
    }
    configure();

    const server = { running: false, token: password, origin: "http://192.0.2.10:7317" };
    const actions = [];
    const commands = [];
    const logs = [];
    let installedRef = ref;
    const controls = { fail: null, hang: false, open: false, rejectToken: false, healthBody: null };
    function run(args) {
        commands.push(args);
        if (args[1] === "list") return `- ${plugin} (Herdr Web UI) ${options.disabled ? "disabled" : "enabled"} [github:${source}@${installedRef}]`;
        if (args[1] === "config-dir") return dirname(envFile);
        if (args[1] === "action") {
            assert.deepEqual(args.slice(0, 3), ["plugin", "action", "invoke"]);
            assert.deepEqual(args.slice(4), ["--plugin", plugin]);
            actions.push(args[3]);
            const log = { action_id: args[3], plugin_id: plugin, log_id: `mock-${logs.length + 1}`, status: "running", exit_code: null, polls: 0 };
            logs.push(log);
            return JSON.stringify({ result: { log } });
        }
        assert.deepEqual(args, ["plugin", "log", "list", "--plugin", plugin, "--limit", "100"]);
        const log = logs.at(-1);
        if (++log.polls > 1 && !controls.hang) {
            log.status = controls.fail === log.action_id ? "failed" : "succeeded";
            log.exit_code = log.status === "succeeded" ? 0 : 1;
            if (log.exit_code === 0) {
                if (log.action_id === "stop") server.running = false;
                if (log.action_id === "start") {
                    const config = loadConfig(envFile);
                    Object.assign(server, { running: true, token: config.env.HERDR_WEB_TOKEN, origin: config.origin });
                }
            }
        }
        return JSON.stringify({ result: { logs } });
    }
    async function request(url, init = {}) {
        assert(!url.includes(password), "token must not be in the request URL");
        const parsed = new URL(url);
        if (!server.running || parsed.origin !== server.origin) throw new Error("mock offline");
        if (parsed.pathname === "/api/health") {
            return Response.json(controls.healthBody ?? { ok: true, web_ui: { boot_id: "mock-boot" } });
        }
        assert.equal(parsed.pathname, "/api/session");
        const allowed = controls.open || (!controls.rejectToken && init.headers?.authorization === `Bearer ${server.token}`);
        return Response.json({}, { status: allowed ? 200 : 401 });
    }
    async function apply(wanted = ref, extra = {}) {
        return reconcile(wanted, { home, stateHome, run, request, wait: async () => {}, ...extra });
    }
    return { home, envFile, ownerFile, stampFile, configure, server, controls, actions, commands, apply,
        stop: () => stopManaged({ home, stateHome, run, wait: async () => {} }),
        installAt: value => { installedRef = value; writeFileSync(ownerFile, `${source}\t${value}\n`); } };
}

test("plugin-compatible parsing preserves special characters without shell/JSON escaping", () => {
    assert.equal(parseEnv(`HERDR_WEB_TOKEN="${password}"\n`).HERDR_WEB_TOKEN, password);
});

test("first apply waits for stop/start and writes only a private version/hash stamp", async t => {
    const f = fixture(t);
    await f.apply();
    assert.deepEqual(f.actions, ["stop", "start"]);
    assert.equal(statSync(f.stampFile).mode & 0o777, 0o600);
    assert.match(readFileSync(f.stampFile, "utf8"), /^v0\.3\.52\n[0-9a-f]{64}\n$/);
    assert(!readFileSync(f.stampFile, "utf8").includes(password));
    assert(!JSON.stringify(f.commands).includes(password));
});

test("unchanged healthy service is not restarted", async t => {
    const f = fixture(t);
    await f.apply();
    f.actions.length = 0;
    await f.apply();
    assert.deepEqual(f.actions, []);
});

test("a stopped service or deleted stamp is recovered without editing the script", async t => {
    const f = fixture(t);
    await f.apply();
    f.server.running = false;
    f.actions.length = 0;
    await f.apply();
    assert.deepEqual(f.actions, ["stop", "start"]);
    rmSync(f.stampFile);
    f.actions.length = 0;
    await f.apply();
    assert.deepEqual(f.actions, ["stop", "start"]);
});

test("new plugin ref replaces the running service", async t => {
    const f = fixture(t);
    await f.apply();
    f.installAt("v0.3.53");
    f.actions.length = 0;
    await f.apply("v0.3.53");
    assert.deepEqual(f.actions, ["stop", "start"]);
    assert.match(readFileSync(f.stampFile, "utf8"), /^v0\.3\.53\n/);
});

test("changing the shared password/host restarts with the exact new values", async t => {
    const f = fixture(t);
    await f.apply();
    f.configure("another mock & \" token", "192.0.2.11");
    f.actions.length = 0;
    await f.apply();
    assert.deepEqual(f.actions, ["stop", "start"]);
    assert.equal(f.server.token, "another mock & \" token");
    assert.equal(f.server.origin, "http://192.0.2.11:7317");
});

for (const failedAction of ["stop", "start"]) {
    test(`failed ${failedAction} does not update a successful stamp`, async t => {
        const f = fixture(t);
        await f.apply();
        const previous = readFileSync(f.stampFile, "utf8");
        f.configure("changed mock token");
        f.controls.fail = failedAction;
        f.actions.length = 0;
        await assert.rejects(f.apply(), /failed/);
        assert.deepEqual(f.actions, failedAction === "stop" ? ["stop"] : ["stop", "start", "stop"]);
        assert.equal(readFileSync(f.stampFile, "utf8"), previous);
    });
}

test("a hung asynchronous action times out without proceeding to start", async t => {
    const f = fixture(t);
    f.controls.hang = true;
    await assert.rejects(f.apply(ref, { actionTimeoutMs: 5, wait: async () => new Promise(resolve => setTimeout(resolve, 10)) }), /Timed out/);
    assert.deepEqual(f.actions, ["stop"]);
    assert(!existsSync(f.stampFile));
});

for (const badAccess of ["open", "rejectToken"]) {
    test(`${badAccess} access fails validation and leaves no success stamp`, async t => {
        const f = fixture(t);
        f.controls[badAccess] = true;
        await assert.rejects(f.apply(), /health\/token-access/);
        assert(!existsSync(f.stampFile));
        assert.deepEqual(f.actions, ["stop", "start", "stop"]);
        assert.equal(f.server.running, false);
    });
}

test("another application's 200/ok response is not treated as Web UI health", async t => {
    const f = fixture(t);
    f.controls.healthBody = { ok: true };
    await assert.rejects(f.apply(), /health\/token-access/);
    assert(!existsSync(f.stampFile));
});

test("empty token is rejected before invoking any service action", async t => {
    const f = fixture(t);
    f.configure("");
    await assert.rejects(f.apply(), /must not be empty/);
    assert.deepEqual(f.actions, []);
});

test("unmanaged and disabled plugins are left alone", async t => {
    const unmanaged = fixture(t, { owned: false });
    assert.equal(await unmanaged.apply(), "skipped");
    assert.deepEqual(unmanaged.commands, []);
    const disabled = fixture(t, { disabled: true });
    assert.equal(await disabled.apply(), "skipped");
    assert.deepEqual(disabled.actions, []);
});

test("profile removal stops the owned service before its action is unregistered", async t => {
    const f = fixture(t);
    f.server.running = true;
    rmSync(f.envFile);
    await f.stop();
    assert.deepEqual(f.actions, ["stop"]);
    assert.equal(f.server.running, false);
});

test("uninstall stop does not adopt unmanaged plugins, and a failed stop aborts", async t => {
    const unmanaged = fixture(t, { owned: false });
    await unmanaged.stop();
    assert.deepEqual(unmanaged.commands, []);
    const f = fixture(t);
    f.controls.fail = "stop";
    await assert.rejects(f.stop(), /stop failed/);
});

test("installation ref mismatch does not restart a different checkout", async t => {
    const f = fixture(t);
    f.installAt("v0.3.53");
    writeFileSync(f.ownerFile, `${source}\t${ref}\n`);
    await assert.rejects(f.apply(), /synchronization first/);
    assert.deepEqual(f.actions, []);
});
