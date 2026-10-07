import { createHash } from "node:crypto";
import { chmodSync, existsSync, mkdirSync, readFileSync, renameSync, rmSync, statSync, writeFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";
import { setTimeout as sleep } from "node:timers/promises";

const SOURCE = "devswha/herdr-web-ui";
const PLUGIN = "devswha.herdr-web-ui";

// Match the plugin's readEnvFile exactly: quotes are stripped, not unescaped.
export function parseEnv(contents) {
    const env = {};
    for (const line of contents.split("\n")) {
        const trimmed = line.trim();
        if (!trimmed || trimmed.startsWith("#")) continue;
        const eq = trimmed.indexOf("=");
        if (eq > 0) env[trimmed.slice(0, eq).trim()] = trimmed.slice(eq + 1).trim().replace(/^["']|["']$/g, "");
    }
    return env;
}

export function loadConfig(file) {
    if (!existsSync(file)) throw new Error("Web UI .env is missing; apply its private template before installing the plugin");
    if ((statSync(file).mode & 0o077) !== 0) throw new Error("Web UI .env must be private (0600)");
    const contents = readFileSync(file, "utf8");
    const env = parseEnv(contents);
    if (!env.HOST || !env.HERDR_WEB_TOKEN) throw new Error("Web UI HOST and HERDR_WEB_TOKEN must not be empty");
    if (env.HERDR_WEB_AUTO_UPDATE !== "0") throw new Error("Web UI automatic updates must be disabled for a dotfiles-managed install");
    if (!/^[0-9]+$/.test(env.PORT ?? "") || Number(env.PORT) < 1 || Number(env.PORT) > 65535) {
        throw new Error("Web UI PORT must be an integer between 1 and 65535");
    }
    const host = env.HOST === "0.0.0.0" ? "127.0.0.1" : env.HOST;
    let origin;
    try { origin = new URL(`http://${host.includes(":") && !host.startsWith("[") ? `[${host}]` : host}:${env.PORT}`).origin; }
    catch { throw new Error("Web UI HOST is not a valid hostname/address"); }
    return { contents, env, origin };
}

function runHerdr(args) {
    const result = Bun.spawnSync(["herdr", ...args], { stdout: "pipe", stderr: "pipe", timeout: 10_000 });
    if (result.exitCode !== 0) throw new Error(`herdr ${args.slice(0, 3).join(" ")} failed; inspect the plugin logs`);
    return result.stdout.toString();
}

export async function waitForAction(name, { run = runHerdr, wait = sleep, actionTimeoutMs = 60_000 } = {}) {
    const invoked = JSON.parse(run(["plugin", "action", "invoke", name, "--plugin", PLUGIN]));
    const logId = invoked.result?.log?.log_id;
    if (typeof logId !== "string") throw new Error(`Web UI ${name} did not return a command log ID`);
    const deadline = Date.now() + actionTimeoutMs;
    while (Date.now() < deadline) {
        const response = JSON.parse(run(["plugin", "log", "list", "--plugin", PLUGIN, "--limit", "100"]));
        if (!Array.isArray(response.result?.logs)) throw new Error("Unexpected Herdr plugin log response");
        const log = response.result.logs.find(entry => entry.log_id === logId);
        if (log && log.status !== "running" && log.status !== "queued") {
            if (log.plugin_id === PLUGIN && log.action_id === name && log.status === "succeeded" && log.exit_code === 0) return;
            throw new Error(`Web UI ${name} failed; inspect herdr plugin log list --plugin ${PLUGIN}`);
        }
        await wait(250);
    }
    throw new Error(`Timed out waiting for Web UI ${name}; the service stamp was not updated`);
}

export async function stopManaged({
    home = homedir(),
    stateHome = process.env.XDG_STATE_HOME || join(home, ".local", "state"),
    run = runHerdr,
    ...actionOptions
} = {}) {
    const ownershipFile = join(stateHome, "chezmoi", "herdr-plugins");
    const ownership = existsSync(ownershipFile) ? readFileSync(ownershipFile, "utf8").split("\n") : [];
    if (!ownership.some(line => line.startsWith(`${SOURCE}\t`))) return;
    if (!run(["plugin", "list"]).includes(`github:${SOURCE}@`)) {
        console.log("    Web UI plugin already absent; no registered stop action is available");
        return;
    }
    console.log("    Stopping dotfiles-owned Web UI before uninstalling its plugin");
    await waitForAction("stop", { run, ...actionOptions });
}

export async function reconcile(ref, {
    home = homedir(),
    stateHome = process.env.XDG_STATE_HOME || join(home, ".local", "state"),
    run = runHerdr,
    request = fetch,
    wait = sleep,
    actionTimeoutMs = 60_000,
} = {}) {
    const stateDir = join(stateHome, "chezmoi");
    const ownershipFile = join(stateDir, "herdr-plugins");
    const ownership = existsSync(ownershipFile) ? readFileSync(ownershipFile, "utf8").split("\n") : [];
    if (!ownership.includes(`${SOURCE}\t${ref}`)) {
        console.log("    Web UI is not owned at the requested ref by dotfiles; skipping service reconciliation");
        return "skipped";
    }

    const installed = run(["plugin", "list"]).split("\n").find(line =>
        line.includes(`github:${SOURCE}@${ref}]`) || line.includes(`github:${SOURCE}@${ref};`));
    if (!installed) throw new Error("Web UI plugin is not at the requested ref; run the [10] plugin synchronization first");
    if (!/\benabled\b/.test(installed)) {
        console.log("    Web UI plugin is disabled; leaving its service alone");
        return "skipped";
    }

    const envFile = join(home, ".config", "herdr", "plugins", "config", PLUGIN, ".env");
    if (run(["plugin", "config-dir", PLUGIN]).trim() !== join(envFile, "..")) {
        throw new Error("Web UI uses a different config directory; refusing to restart with an unmanaged .env");
    }
    const { contents, env, origin } = loadConfig(envFile);
    const fingerprint = `${ref}\n${createHash("sha256").update(contents).digest("hex")}\n`;
    const stampFile = join(stateDir, "herdr-web-ui");
    const previous = existsSync(stampFile) ? readFileSync(stampFile, "utf8") : "";

    async function healthy() {
        try {
            const response = await request(`${origin}/api/health`, { signal: AbortSignal.timeout(1500) });
            if (!response.ok) return false;
            const body = await response.json();
            return body.ok === true && body.web_ui != null && "boot_id" in body.web_ui;
        } catch { return false; }
    }

    async function authenticated() {
        // Do not put the token in argv, URLs, diagnostics, or Herdr command logs.
        try {
            const anonymous = await request(`${origin}/api/session`, { signal: AbortSignal.timeout(1500) });
            if (anonymous.status !== 401) return false;
            const signedIn = await request(`${origin}/api/session`, {
                headers: { authorization: `Bearer ${env.HERDR_WEB_TOKEN}` },
                signal: AbortSignal.timeout(1500),
            });
            return signedIn.ok;
        } catch { return false; }
    }

    if (previous === fingerprint && await healthy() && await authenticated()) {
        console.log("    Herdr Web UI service already synchronized");
        return "synchronized";
    }

    const action = name => waitForAction(name, { run, wait, actionTimeoutMs });

    console.log("    Reconciling Herdr Web UI service (stop, then start)");
    // start alone leaves an old process alive. stop waits for the supervisor's
    // lock to be released; do not race it by merely sleeping a fixed duration.
    await action("stop");
    try {
        await action("start");
        if (!await healthy() || !await authenticated()) {
            throw new Error("Web UI failed health/token-access checks; the service stamp was not updated");
        }
    } catch (error) {
        // A failed startup/access check must not leave an unverified LAN
        // service running. Only the plugin's own supervisor is stopped.
        try { await action("stop"); }
        catch { throw new Error("Web UI startup/access verification and cleanup stop failed; inspect the plugin logs"); }
        throw error;
    }

    mkdirSync(stateDir, { recursive: true, mode: 0o700 });
    const temporary = `${stampFile}.tmp-${process.pid}`;
    try {
        writeFileSync(temporary, fingerprint, { mode: 0o600 });
        chmodSync(temporary, 0o600);
        renameSync(temporary, stampFile);
    } finally { rmSync(temporary, { force: true }); }
    console.log("    Herdr Web UI service synchronized; token values were not printed");
    return "synchronized";
}

if (import.meta.main) {
    try {
        if (process.argv[2] === "--check-config") loadConfig(process.argv[3]);
        else if (process.argv[2] === "--stop-managed") await stopManaged();
        else await reconcile(process.argv[2]);
    } catch (error) {
        console.error(`    Error: ${error.message}`);
        process.exitCode = 1;
    }
}
