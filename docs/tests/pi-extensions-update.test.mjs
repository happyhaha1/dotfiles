import assert from "node:assert/strict";
import {
  chmodSync, existsSync, mkdirSync, mkdtempSync, readFileSync, readdirSync, rmSync,
  symlinkSync, writeFileSync,
} from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";
import test from "node:test";

const sourceRoot = fileURLToPath(new URL("../../", import.meta.url));
const helperSource = readFileSync(join(sourceRoot, "private_dot_local/bin/executable_pi-extensions-update"), "utf8");
const justSource = readFileSync(join(sourceRoot, "Justfile.tmpl"), "utf8");
const updateCommand = "update --extensions --no-approve";

function executable(path, content) {
  mkdirSync(dirname(path), { recursive: true });
  writeFileSync(path, content, { mode: 0o755 });
  chmodSync(path, 0o755);
}

function fixture(t, {
  managed = true, payload = true, initialized = true, settings = true,
  customPi = false, customAqua = false, customXdg = false, omarchy = false,
} = {}) {
  const root = mkdtempSync(join(tmpdir(), "pi-extensions-"));
  t.after(() => rmSync(root, { recursive: true, force: true }));
  const home = join(root, "home with spaces");
  const bin = join(root, "mock-bin");
  const log = join(root, "events");
  const resolverLog = join(root, "resolver-events");
  const env = {
    ...process.env,
    HOME: home,
    XDG_CONFIG_HOME: join(home, ".config"),
    XDG_STATE_HOME: join(home, ".local/state"),
    XDG_DATA_HOME: customXdg ? join(root, "custom data") : join(home, ".local/share"),
    PATH: `${bin}:/usr/bin:/bin`,
    TEST_EVENTS: log,
    TEST_RESOLVER_EVENTS: resolverLog,
    TEST_PI_EXIT: "0",
    TEST_AQUA_EXIT: "0",
  };
  // Do not accidentally rely on Aqua configuration inherited from Fish.
  for (const name of ["AQUA_ROOT_DIR", "AQUA_CONFIG", "AQUA_GLOBAL_CONFIG", "AQUA_POLICY_CONFIG", "AQUA_DISABLE_LAZY_INSTALL", "PI_CODING_AGENT_DIR"]) delete env[name];
  if (customAqua) env.AQUA_ROOT_DIR = join(root, "custom Aqua root");
  if (customPi) env.PI_CODING_AGENT_DIR = join(root, "custom Pi agent");
  const aquaRoot = env.AQUA_ROOT_DIR || join(env.XDG_DATA_HOME, "aquaproj-aqua");
  const piDir = env.PI_CODING_AGENT_DIR || join(home, ".pi/agent");
  const helper = join(home, ".local/bin/pi-extensions-update");
  const herdrHelper = join(home, ".local/bin/herdr-integrations-sync");
  const piPayload = join(aquaRoot, "pkgs/github_release/pi/test/pi");
  const configDir = join(home, ".config/aquaproj-aqua");
  const config = join(configDir, omarchy ? "aqua-omarchy.yaml" : "aqua.yaml");
  const policy = join(configDir, "aqua-policy.yaml");
  env.TEST_EXPECT_CONFIG = config;
  env.TEST_EXPECT_POLICY = policy;
  mkdirSync(configDir, { recursive: true });
  writeFileSync(config, "packages: []\n");
  writeFileSync(policy, "packages: []\n");
  mkdirSync(bin, { recursive: true });
  writeFileSync(log, "");
  writeFileSync(resolverLog, "");
  symlinkSync("/bin/bash", join(bin, "bash"));
  executable(helper, helperSource);
  // The shared Herdr synchronizer is a separate concern; stub it so the
  // maintenance recipes under test exercise only their own ordering.
  executable(herdrHelper, `#!/bin/bash
printf 'herdr-integrations-sync\\n' >> "$TEST_EVENTS"
exit "\${TEST_HERDR_SYNC_EXIT:-0}"
`);
  if (initialized) {
    mkdirSync(piDir, { recursive: true });
    if (settings) writeFileSync(join(piDir, "settings.json"), "{}\n");
  }

  // Model Aqua's actual proxy shape, not a direct CLI in its bin directory.
  // Invoking either the proxy or a PATH fallback is always a test failure.
  executable(join(bin, "pi"), '#!/bin/bash\nprintf "unexpected PATH Pi\\n" >> "$TEST_EVENTS"\nexit 99\n');
  if (managed) {
    executable(join(aquaRoot, "aqua-proxy"), '#!/bin/bash\nprintf "unexpected Aqua proxy\\n" >> "$TEST_EVENTS"\nexit 99\n');
    mkdirSync(join(aquaRoot, "bin"), { recursive: true });
    symlinkSync("../aqua-proxy", join(aquaRoot, "bin/pi"));
  }
  executable(join(aquaRoot, "bin/aqua"), `#!/bin/bash
set -euo pipefail
if [[ "\${1:-}" == -c ]]; then
    printf 'which pi\\n' >> "$TEST_RESOLVER_EVENTS"
    [[ "$#" == 4 && "$2" == "$TEST_EXPECT_CONFIG" && "$3" == which && "$4" == pi ]] || exit 99
    [[ "$AQUA_CONFIG" == "$TEST_EXPECT_CONFIG" && "$AQUA_GLOBAL_CONFIG" == "$TEST_EXPECT_CONFIG" ]] || exit 99
    [[ "$AQUA_POLICY_CONFIG" == "$TEST_EXPECT_POLICY" && "$AQUA_DISABLE_LAZY_INSTALL" == true ]] || exit 99
    if [[ "\${TEST_RESOLVE_EXIT:-0}" != 0 ]]; then
        echo 'mock resolver failed' >&2
        exit "$TEST_RESOLVE_EXIT"
    fi
    printf '%s\\n' "\${TEST_RESOLVED_PI:-$AQUA_ROOT_DIR/pkgs/github_release/pi/test/pi}"
    exit 0
fi
exit 99
`);
  if (managed && payload) executable(piPayload, `#!/bin/bash
set -euo pipefail
printf 'pi %s\\n' "$*" >> "$TEST_EVENTS"
[[ "$*" == '${updateCommand}' ]] || exit 99
if [[ "$TEST_PI_EXIT" != 0 ]]; then
    echo 'mock pi update failed' >&2
    exit "$TEST_PI_EXIT"
fi
`);

  for (const command of ["aqua", "chezmoi", "mise", "brew"]) {
    executable(join(bin, command), `#!/bin/bash
printf '${command} %s\\n' "$*" >> "$TEST_EVENTS"
${command === "aqua" ? 'exit "$TEST_AQUA_EXIT"' : "exit 0"}
`);
  }
  return { root, home, env, piDir, aquaRoot, helper, piPayload, log, resolverLog, config };
}

function run(f, script, isCommand = false) {
  const args = ["-euo", "pipefail", ...(isCommand ? ["-c", script] : [script])];
  const result = spawnSync("/bin/bash", args, { env: f.env, cwd: f.home, encoding: "utf8", timeout: 10_000 });
  assert.ifError(result.error);
  return result;
}

function events(f) {
  return readFileSync(f.log, "utf8").trim().split("\n").filter(Boolean);
}

// These recipe bodies contain no template expressions. Exercise each command
// in the strict Bash shell configured by Justfile, preserving its fail-fast
// behavior; local verification additionally renders and runs the actual just CLI.
function runRecipe(f, name) {
  const lines = justSource.split("\n");
  const start = lines.indexOf(`${name}:`);
  assert.notEqual(start, -1, `recipe ${name} must exist`);
  const commands = [];
  for (const line of lines.slice(start + 1)) {
    if (!line.startsWith("    ")) break;
    const command = line.slice(4).replace(/^@/, "");
    assert(!command.includes("{{"), "rendering would be required for a templated command");
    commands.push(command);
  }
  assert(commands.length > 0);
  for (const command of commands) {
    const result = run(f, command, true);
    if (result.status !== 0) return result;
  }
  return { status: 0 };
}

test("updates user packages through the resolved Aqua payload", (t) => {
  const f = fixture(t);
  assert.equal(run(f, f.helper).status, 0);
  assert.deepEqual(events(f), [`pi ${updateCommand}`]);
});

test("repeated updates stay idempotent and never touch the Aqua proxy", (t) => {
  const f = fixture(t);
  assert.equal(run(f, f.helper).status, 0);
  assert.equal(run(f, f.helper).status, 0);
  assert.deepEqual(events(f), [`pi ${updateCommand}`, `pi ${updateCommand}`]);
});

test("missing Aqua-managed Pi skips even if a wrapper is on PATH", (t) => {
  const f = fixture(t, { managed: false });
  const result = run(f, f.helper);
  assert.equal(result.status, 0);
  assert.match(result.stdout, /Skipped.*Aqua-managed Pi is not installed/);
  assert.deepEqual(events(f), []);
});

test("an uninitialized Pi is skipped without creating its directory", (t) => {
  const f = fixture(t, { initialized: false });
  const result = run(f, f.helper);
  assert.equal(result.status, 0);
  assert.match(result.stdout, /Skipped.*Pi agent directory/);
  assert(!existsSync(f.piDir));
  assert.deepEqual(events(f), []);
});

test("Pi without user settings is skipped before resolution", (t) => {
  const f = fixture(t, { settings: false });
  const result = run(f, f.helper);
  assert.equal(result.status, 0);
  assert.match(result.stdout, /Skipped.*no user settings/);
  assert.equal(readFileSync(f.resolverLog, "utf8"), "");
  assert.deepEqual(events(f), []);
});

test("an executable Aqua proxy with a missing payload skips without invoking the proxy", (t) => {
  const f = fixture(t, { payload: false });
  const result = run(f, f.helper);
  assert.equal(result.status, 0);
  assert.match(result.stdout, /Skipped.*payload is not installed/);
  assert.deepEqual(events(f), []);
});

test("rejects an Aqua resolver PATH fallback rather than executing another Pi", (t) => {
  const f = fixture(t);
  f.env.TEST_RESOLVED_PI = join(f.root, "mock-bin/pi");
  const result = run(f, f.helper);
  assert.equal(result.status, 0);
  assert.match(result.stdout, /Skipped.*not resolved to an Aqua package/);
  assert.deepEqual(events(f), []);
});

test("missing Aqua configuration skips before resolution", (t) => {
  const f = fixture(t);
  rmSync(f.config);
  const result = run(f, f.helper);
  assert.equal(result.status, 0);
  assert.match(result.stdout, /Skipped.*configuration is not installed/);
  assert.equal(readFileSync(f.resolverLog, "utf8"), "");
  assert.deepEqual(events(f), []);
});

test("Aqua resolution failures retain their exit code and never run Pi", (t) => {
  const f = fixture(t);
  f.env.TEST_RESOLVE_EXIT = "28";
  const result = run(f, f.helper);
  assert.equal(result.status, 28);
  assert.match(result.stderr, /mock resolver failed/);
  assert.deepEqual(events(f), []);
});

test("Pi updater failures keep their exit code", (t) => {
  const f = fixture(t);
  f.env.TEST_PI_EXIT = "37";
  const result = run(f, f.helper);
  assert.equal(result.status, 37);
  assert.match(result.stderr, /mock pi update failed/);
});

for (const [label, options] of [
  ["PI_CODING_AGENT_DIR", { customPi: true }],
  ["XDG_DATA_HOME", { customXdg: true }],
  ["AQUA_ROOT_DIR precedence over XDG_DATA_HOME", { customAqua: true, customXdg: true }],
]) {
  test(`respects ${label}, including paths with spaces`, (t) => {
    const f = fixture(t, options);
    assert.equal(run(f, f.helper).status, 0);
    assert.deepEqual(events(f), [`pi ${updateCommand}`]);
  });
}

test("a missing custom Pi directory never falls back to the default directory", (t) => {
  const f = fixture(t, { customPi: true, initialized: false });
  mkdirSync(join(f.home, ".pi/agent"), { recursive: true });
  writeFileSync(join(f.home, ".pi/agent/settings.json"), "{}\n");
  assert.equal(run(f, f.helper).status, 0);
  assert(!existsSync(f.piDir));
  assert.deepEqual(events(f), []);
});

test("normalizes a relative AQUA_ROOT_DIR before checking resolved package ownership", (t) => {
  const f = fixture(t);
  f.env.AQUA_ROOT_DIR = ".local/share/aquaproj-aqua";
  assert.equal(run(f, f.helper).status, 0);
  assert.deepEqual(events(f), [`pi ${updateCommand}`]);
});

test("restores Aqua configuration without shell exports, including Omarchy selection", (t) => {
  const f = fixture(t, { omarchy: true });
  assert.equal(f.env.AQUA_CONFIG, undefined);
  assert.equal(f.env.AQUA_GLOBAL_CONFIG, undefined);
  assert.equal(run(f, f.helper).status, 0);
  assert.equal(readFileSync(f.resolverLog, "utf8"), "which pi\n");
  assert.deepEqual(events(f), [`pi ${updateCommand}`]);
});

test("honors explicit Aqua manifest and policy overrides", (t) => {
  const f = fixture(t);
  const config = join(f.root, "custom aqua.yaml");
  const policy = join(f.root, "custom aqua-policy.yaml");
  writeFileSync(config, "packages: []\n");
  writeFileSync(policy, "packages: []\n");
  Object.assign(f.env, { AQUA_CONFIG: config, AQUA_POLICY_CONFIG: policy, TEST_EXPECT_CONFIG: config, TEST_EXPECT_POLICY: policy });
  assert.equal(run(f, f.helper).status, 0);
  assert.deepEqual(events(f), [`pi ${updateCommand}`]);
});

test("the recipe delegates to the shared helper and preserves failures", (t) => {
  const f = fixture(t);
  assert.equal(runRecipe(f, "pi-extensions-update").status, 0);
  assert.deepEqual(events(f), [`pi ${updateCommand}`]);

  const failing = fixture(t);
  failing.env.TEST_PI_EXIT = "37";
  assert.equal(runRecipe(failing, "pi-extensions-update").status, 37);
});

test("apply-time Aqua installation never updates Pi packages", (t) => {
  const f = fixture(t);
  assert.equal(runRecipe(f, "aqua-install").status, 0);
  assert(!events(f).some((line) => line.startsWith("pi ")), events(f).join("\n"));
});

test("no chezmoi apply script updates Pi packages", () => {
  const scripts = readdirSync(join(sourceRoot, ".chezmoiscripts"));
  assert(scripts.length > 0);
  for (const script of scripts) {
    const body = readFileSync(join(sourceRoot, ".chezmoiscripts", script), "utf8");
    assert(!body.includes("pi-extensions-update"), `${script} must not update Pi packages`);
  }
});

for (const name of ["update-all", "full-upgrade"]) {
  test(`${name} updates Pi packages after mise and before Homebrew`, (t) => {
    const f = fixture(t);
    assert.equal(runRecipe(f, name).status, 0);
    const calls = events(f);
    const mise = calls.indexOf("mise upgrade");
    const pi = calls.indexOf(`pi ${updateCommand}`);
    const brew = calls.indexOf("brew update");
    assert(mise >= 0 && pi > mise && brew > pi, calls.join("\n"));
  });

  test(`${name} does not swallow Pi updater failures`, (t) => {
    const f = fixture(t);
    f.env.TEST_PI_EXIT = "37";
    assert.equal(runRecipe(f, name).status, 37);
  });

  test(`${name} keeps the Pi update independent of the Aqua install result`, (t) => {
    const f = fixture(t);
    f.env.TEST_AQUA_EXIT = "12";
    assert.equal(runRecipe(f, name).status, 0);
    assert(events(f).includes(`pi ${updateCommand}`), events(f).join("\n"));
    assert(!events(f).includes("herdr-integrations-sync"), events(f).join("\n"));
  });
}
