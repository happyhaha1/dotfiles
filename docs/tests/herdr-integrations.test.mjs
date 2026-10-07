import assert from "node:assert/strict";
import {
  chmodSync, existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync,
  symlinkSync, writeFileSync,
} from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";
import test from "node:test";

const sourceRoot = fileURLToPath(new URL("../../", import.meta.url));
const helperSource = readFileSync(join(sourceRoot, "private_dot_local/bin/executable_herdr-integrations-sync"), "utf8");
const orchestrationSource = readFileSync(join(sourceRoot, ".chezmoiscripts/run_after_10_herdr.sh.tmpl"), "utf8");
const applyMarker = "# Run every full apply:";
assert(orchestrationSource.includes(applyMarker));
const applySource = orchestrationSource.slice(orchestrationSource.indexOf(applyMarker));
const hookSource = applySource.split("\n").find((line) => line === '"$HOME/.local/bin/herdr-integrations-sync"');
assert(hookSource, "the integration helper must be called unconditionally");
const justSource = readFileSync(join(sourceRoot, "Justfile.tmpl"), "utf8");

function executable(path, content) {
  mkdirSync(dirname(path), { recursive: true });
  writeFileSync(path, content, { mode: 0o755 });
  chmodSync(path, 0o755);
}

function fixture(t, { managed = true, payload = true, initialized = true, customPi = false, customAqua = false, customXdg = false, omarchy = false } = {}) {
  const root = mkdtempSync(join(tmpdir(), "herdr-integrations-"));
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
    TEST_INTEGRATION_VERSION: "9",
    TEST_INSTALL_EXIT: "0",
    TEST_AQUA_EXIT: "0",
  };
  // Do not accidentally rely on Aqua configuration inherited from Fish.
  for (const name of ["AQUA_ROOT_DIR", "AQUA_CONFIG", "AQUA_GLOBAL_CONFIG", "AQUA_POLICY_CONFIG", "AQUA_DISABLE_LAZY_INSTALL", "PI_CODING_AGENT_DIR"]) delete env[name];
  if (customAqua) env.AQUA_ROOT_DIR = join(root, "custom Aqua root");
  if (customPi) env.PI_CODING_AGENT_DIR = join(root, "custom Pi agent");
  const aquaRoot = env.AQUA_ROOT_DIR || join(env.XDG_DATA_HOME, "aquaproj-aqua");
  const piDir = env.PI_CODING_AGENT_DIR || join(home, ".pi/agent");
  const helper = join(home, ".local/bin/herdr-integrations-sync");
  const extension = join(piDir, "extensions/herdr-agent-state.ts");
  const herdrPayload = join(aquaRoot, "pkgs/github_release/herdr/test/herdr");
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
  if (initialized) mkdirSync(piDir, { recursive: true });

  // Model Aqua's actual proxy shape, not a direct CLI in its bin directory.
  // Invoking either proxy or PATH fallback is always a test failure.
  executable(join(bin, "herdr"), '#!/bin/bash\nprintf "unexpected PATH Herdr\\n" >> "$TEST_EVENTS"\nexit 99\n');
  if (managed) {
    executable(join(aquaRoot, "aqua-proxy"), '#!/bin/bash\nprintf "unexpected Aqua proxy\\n" >> "$TEST_EVENTS"\nexit 99\n');
    mkdirSync(join(aquaRoot, "bin"), { recursive: true });
    symlinkSync("../aqua-proxy", join(aquaRoot, "bin/herdr"));
  }
  executable(join(aquaRoot, "bin/aqua"), `#!/bin/bash
set -euo pipefail
printf 'which herdr\n' >> "$TEST_RESOLVER_EVENTS"
[[ "$#" == 4 && "$1" == -c && "$2" == "$TEST_EXPECT_CONFIG" && "$3" == which && "$4" == herdr ]] || exit 99
[[ "$AQUA_CONFIG" == "$TEST_EXPECT_CONFIG" && "$AQUA_GLOBAL_CONFIG" == "$TEST_EXPECT_CONFIG" ]] || exit 99
[[ "$AQUA_POLICY_CONFIG" == "$TEST_EXPECT_POLICY" && "$AQUA_DISABLE_LAZY_INSTALL" == true ]] || exit 99
if [[ "\${TEST_RESOLVE_EXIT:-0}" != 0 ]]; then
    echo 'mock resolver failed' >&2
    exit "$TEST_RESOLVE_EXIT"
fi
printf '%s\n' "\${TEST_RESOLVED_HERDR:-$AQUA_ROOT_DIR/pkgs/github_release/herdr/test/herdr}"
`);
  if (managed && payload) executable(herdrPayload, `#!/bin/bash
set -euo pipefail
printf 'herdr %s\n' "$*" >> "$TEST_EVENTS"
[[ "$*" == 'integration install pi' ]] || exit 99
if [[ "$TEST_INSTALL_EXIT" != 0 ]]; then
    echo 'mock installer failed' >&2
    exit "$TEST_INSTALL_EXIT"
fi
agent_dir="\${PI_CODING_AGENT_DIR-$HOME/.pi/agent}"
mkdir -p "$agent_dir/extensions"
printf 'bundled integration v%s\n' "$TEST_INTEGRATION_VERSION" > "$agent_dir/extensions/herdr-agent-state.ts"
`);

  for (const command of ["aqua", "chezmoi", "mise", "sheldon", "brew"]) {
    executable(join(bin, command), `#!/bin/bash
printf '${command} %s\n' "$*" >> "$TEST_EVENTS"
${command === "aqua" ? 'exit "$TEST_AQUA_EXIT"' : "exit 0"}
`);
  }
  return { root, home, env, piDir, aquaRoot, helper, extension, log, resolverLog, herdrPayload, config };
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

test("installs only the current Aqua CLI's bundled Pi integration", (t) => {
  const f = fixture(t);
  assert.equal(run(f, f.helper).status, 0);
  assert.deepEqual(events(f), ["herdr integration install pi"]);
  assert.equal(readFileSync(f.extension, "utf8"), "bundled integration v9\n");
});

test("repeated syncs leave one integration file with the same content", (t) => {
  const f = fixture(t);
  assert.equal(run(f, f.helper).status, 0);
  const first = readFileSync(f.extension, "utf8");
  assert.equal(run(f, f.helper).status, 0);
  assert.equal(readFileSync(f.extension, "utf8"), first);
  assert.equal(events(f).length, 2);
});

test("a newer CLI's bundled version replaces the previous integration", (t) => {
  const f = fixture(t);
  assert.equal(run(f, f.helper).status, 0);
  f.env.TEST_INTEGRATION_VERSION = "10";
  assert.equal(run(f, f.helper).status, 0);
  assert.equal(readFileSync(f.extension, "utf8"), "bundled integration v10\n");
});

test("the unconditional after hook repairs a deleted extension on the next run", (t) => {
  const f = fixture(t);
  assert(hookSource.includes('"$HOME/.local/bin/herdr-integrations-sync"'));
  assert(!hookSource.includes("{{"), "the hook must not be gated by profile or template state");
  assert.equal(run(f, hookSource, true).status, 0);
  rmSync(f.extension);
  assert.equal(run(f, hookSource, true).status, 0);
  assert(existsSync(f.extension));
  assert.equal(events(f).length, 2);
});

test("missing Aqua-managed Herdr skips even if a wrapper is on PATH", (t) => {
  const f = fixture(t, { managed: false });
  const result = run(f, f.helper);
  assert.equal(result.status, 0);
  assert.match(result.stdout, /Skipped.*Herdr/);
  assert.deepEqual(events(f), []);
  assert(!existsSync(f.extension));
});

test("an uninitialized Pi is skipped without creating its directory", (t) => {
  const f = fixture(t, { initialized: false });
  const result = run(f, f.helper);
  assert.equal(result.status, 0);
  assert.match(result.stdout, /Skipped.*Pi agent directory/);
  assert(!existsSync(f.piDir));
  assert.deepEqual(events(f), []);
});

for (const [label, options] of [
  ["PI_CODING_AGENT_DIR", { customPi: true }],
  ["XDG_DATA_HOME", { customXdg: true }],
  ["AQUA_ROOT_DIR precedence over XDG_DATA_HOME", { customAqua: true, customXdg: true }],
]) {
  test(`respects ${label}, including paths with spaces`, (t) => {
    const f = fixture(t, options);
    assert.equal(run(f, f.helper).status, 0);
    assert(existsSync(f.extension));
    assert.deepEqual(events(f), ["herdr integration install pi"]);
  });
}

test("a missing custom Pi directory never falls back to the default directory", (t) => {
  const f = fixture(t, { customPi: true, initialized: false });
  mkdirSync(join(f.home, ".pi/agent"), { recursive: true });
  assert.equal(run(f, f.helper).status, 0);
  assert(!existsSync(f.piDir));
  assert.deepEqual(events(f), []);
});

test("installer errors keep their exit code and the previous file", (t) => {
  const f = fixture(t);
  assert.equal(run(f, f.helper).status, 0);
  const before = readFileSync(f.extension, "utf8");
  f.env.TEST_INSTALL_EXIT = "37";
  const result = run(f, f.helper);
  assert.equal(result.status, 37);
  assert.match(result.stderr, /mock installer failed/);
  assert.equal(readFileSync(f.extension, "utf8"), before);
});

const stubPhases = `
sync_herdr_plugins() (
  printf 'phase plugins\\n' >> "$TEST_EVENTS"
  export HERDR_PLUGIN_SCOPE=plugin
  exit "\${TEST_PLUGIN_EXIT:-0}"
)
sync_herdr_web_ui() (
  [[ -z "\${HERDR_PLUGIN_SCOPE+x}" ]] || exit 99
  printf 'phase web-ui\\n' >> "$TEST_EVENTS"
  export HERDR_WEB_SCOPE=web-ui
  exit "\${TEST_WEB_UI_EXIT:-0}"
)
sync_roamgate() (
  [[ -z "\${HERDR_PLUGIN_SCOPE+x}" && -z "\${HERDR_WEB_SCOPE+x}" ]] || exit 99
  printf 'phase roamgate\\n' >> "$TEST_EVENTS"
  exit "\${TEST_ROAMGATE_EXIT:-0}"
)
`;

test("one unconditional entry replaces every separate Herdr service script", () => {
  for (const retired of [
    "run_after_09_herdr-integrations.sh.tmpl",
    "run_onchange_after_10_herdr-plugins.sh.tmpl",
    "run_after_11_herdr-web-ui.sh.tmpl",
    "run_after_12_roamgate.sh.tmpl",
  ]) assert(!existsSync(join(sourceRoot, ".chezmoiscripts", retired)), retired);
  assert(orchestrationSource.includes("sync_herdr_plugins() ("));
  assert(orchestrationSource.includes("sync_herdr_web_ui() ("));
  assert(orchestrationSource.includes("sync_roamgate() ("));
  assert(!applySource.includes("{{"), "profile gates belong inside phases, not around the entry");
});

test("the combined entry invokes integrations, plugins, Web UI, and Roamgate in order", (t) => {
  const f = fixture(t);
  assert.equal(run(f, stubPhases + applySource, true).status, 0);
  assert.deepEqual(events(f), ["herdr integration install pi", "phase plugins", "phase web-ui", "phase roamgate"]);
});

test("a failed integration prevents every later phase", (t) => {
  const f = fixture(t);
  f.env.TEST_INSTALL_EXIT = "37";
  assert.equal(run(f, stubPhases + applySource, true).status, 37);
  assert.deepEqual(events(f), ["herdr integration install pi"]);
});

test("a failed plugin phase prevents both service phases", (t) => {
  const f = fixture(t);
  f.env.TEST_PLUGIN_EXIT = "31";
  assert.equal(run(f, stubPhases + applySource, true).status, 31);
  assert.deepEqual(events(f), ["herdr integration install pi", "phase plugins"]);
});

test("a plugin phase exit zero and its environment stay local to that phase", (t) => {
  const f = fixture(t);
  assert.equal(run(f, stubPhases + applySource, true).status, 0);
  assert.deepEqual(events(f), ["herdr integration install pi", "phase plugins", "phase web-ui", "phase roamgate"]);
});

test("Web UI failure prevents Roamgate synchronization", (t) => {
  const f = fixture(t);
  f.env.TEST_WEB_UI_EXIT = "42";
  assert.equal(run(f, stubPhases + applySource, true).status, 42);
  assert.deepEqual(events(f), ["herdr integration install pi", "phase plugins", "phase web-ui"]);
});

test("Roamgate failure remains a failure of the combined entry", (t) => {
  const f = fixture(t);
  f.env.TEST_ROAMGATE_EXIT = "43";
  assert.equal(run(f, stubPhases + applySource, true).status, 43);
  assert.deepEqual(events(f), ["herdr integration install pi", "phase plugins", "phase web-ui", "phase roamgate"]);
});

test("normalizes a relative AQUA_ROOT_DIR before checking resolved package ownership", (t) => {
  const f = fixture(t);
  f.env.AQUA_ROOT_DIR = ".local/share/aquaproj-aqua";
  assert.equal(run(f, f.helper).status, 0);
  assert(existsSync(f.extension));
  assert.deepEqual(events(f), ["herdr integration install pi"]);
});

test("restores Aqua configuration without shell exports, including Omarchy selection", (t) => {
  const f = fixture(t, { omarchy: true });
  assert.equal(f.env.AQUA_CONFIG, undefined);
  assert.equal(f.env.AQUA_GLOBAL_CONFIG, undefined);
  assert.equal(run(f, f.helper).status, 0);
  assert.equal(readFileSync(f.resolverLog, "utf8"), "which herdr\n");
  assert(existsSync(f.extension));
});

test("honors explicit Aqua manifest and policy overrides", (t) => {
  const f = fixture(t);
  const config = join(f.root, "custom aqua.yaml");
  const policy = join(f.root, "custom aqua-policy.yaml");
  writeFileSync(config, "packages: []\n");
  writeFileSync(policy, "packages: []\n");
  Object.assign(f.env, { AQUA_CONFIG: config, AQUA_POLICY_CONFIG: policy, TEST_EXPECT_CONFIG: config, TEST_EXPECT_POLICY: policy });
  assert.equal(run(f, f.helper).status, 0);
  assert(existsSync(f.extension));
});

test("an executable Aqua proxy with a missing payload skips without invoking the proxy", (t) => {
  const f = fixture(t, { payload: false });
  const result = run(f, f.helper);
  assert.equal(result.status, 0);
  assert.match(result.stdout, /Skipped.*payload is not installed/);
  assert.deepEqual(events(f), []);
  assert(!existsSync(f.herdrPayload));
  assert(!existsSync(f.extension));
});

test("rejects an Aqua resolver PATH fallback rather than executing another Herdr", (t) => {
  const f = fixture(t);
  f.env.TEST_RESOLVED_HERDR = join(f.root, "mock-bin/herdr");
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

test("Aqua resolution failures retain their exit code and never run the installer", (t) => {
  const f = fixture(t);
  f.env.TEST_RESOLVE_EXIT = "28";
  const result = run(f, f.helper);
  assert.equal(result.status, 28);
  assert.match(result.stderr, /mock resolver failed/);
  assert.deepEqual(events(f), []);
});

for (const name of ["aqua-install", "update-all", "full-upgrade"]) {
  test(`${name} syncs after Aqua succeeds and before cleanup`, (t) => {
    const f = fixture(t);
    assert.equal(runRecipe(f, name).status, 0);
    const calls = events(f);
    const aqua = calls.indexOf("aqua install");
    const sync = calls.indexOf("herdr integration install pi");
    assert(aqua >= 0 && sync > aqua, calls.join("\n"));
    const vacuum = calls.indexOf("aqua vacuum --init");
    if (vacuum >= 0) assert(vacuum > sync);
  });

  test(`${name} does not swallow integration installation failures`, (t) => {
    const f = fixture(t);
    f.env.TEST_INSTALL_EXIT = "37";
    assert.equal(runRecipe(f, name).status, 37);
    assert.deepEqual(events(f).filter((line) => !line.startsWith("chezmoi ")), [
      "aqua install", "herdr integration install pi",
    ]);
  });

  test(`${name} skips sync when Aqua fails, preserving existing Aqua error policy`, (t) => {
    const f = fixture(t);
    f.env.TEST_AQUA_EXIT = "12";
    assert.equal(runRecipe(f, name).status, name === "aqua-install" ? 12 : 0);
    assert(!events(f).some((line) => line.startsWith("herdr ")));
    assert(!existsSync(f.extension));
  });
}
