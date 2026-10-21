import assert from 'node:assert/strict';
import { existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { spawnSync } from 'node:child_process';
import test from 'node:test';

const source = readFileSync(new URL('../../private_dot_local/bin/executable_pi-extensions-update', import.meta.url), 'utf8');
function fixture(t) {
  const root = mkdtempSync(join(tmpdir(), 'pi-mise-'));
  t.after(() => rmSync(root, { recursive: true, force: true }));
  const home = join(root, 'home with spaces');
  const bin = join(root, 'bin');
  const pkg = join(root, 'Pi package');
  const agent = join(home, '.pi/agent');
  for (const path of [bin, agent, join(pkg, 'bin')]) mkdirSync(path, { recursive: true });
  writeFileSync(join(agent, 'settings.json'), '{}');
  writeFileSync(join(pkg, 'bin/pi'), 'payload');
  const helper = join(root, 'helper');
  writeFileSync(helper, source);
  writeFileSync(join(bin, 'mise'), `#!/bin/bash
if [[ "$PWD" != "$HOME" ]]; then exit 98; fi
if [[ "\${TEST_RESOLVE_EXIT:-0}" != 0 ]]; then exit "$TEST_RESOLVE_EXIT"; fi
case "$*" in
  'where npm:@earendil-works/pi-coding-agent') printf '%s\\n' "$TEST_PACKAGE" ;;
  'which node') printf '%s\\n' "$TEST_NODE" ;;
  *) exit 99 ;;
esac
`, { mode: 0o755 });
  writeFileSync(join(bin, 'node'), `#!/bin/bash
[[ "$1" == "$TEST_PACKAGE/bin/pi" ]] || exit 99
shift
printf '%s\\n' "$*" > "$TEST_LOG"
exit "\${TEST_PI_EXIT:-0}"
`, { mode: 0o755 });
  const env = { ...process.env, HOME: home, PATH: `${bin}:/usr/bin:/bin`, TEST_PACKAGE: pkg, TEST_NODE: join(bin, 'node'), TEST_LOG: join(root, 'calls') };
  delete env.PI_CODING_AGENT_DIR;
  return { root, home, bin, pkg, agent, helper, env };
}
function run(f) {
  const result = spawnSync('/bin/bash', [f.helper], { cwd: f.root, env: f.env, encoding: 'utf8', timeout: 10000 });
  assert.ifError(result.error);
  return result;
}

test('updates user extensions through Node, resolving global tools outside the project', t => {
  const f = fixture(t);
  assert.equal(run(f).status, 0);
  assert.equal(readFileSync(f.env.TEST_LOG, 'utf8'), 'update --extensions --no-approve\n');
});
test('missing agent stays uninitialized', t => {
  const f = fixture(t);
  rmSync(f.agent, { recursive: true });
  assert.equal(run(f).status, 0);
  assert.equal(existsSync(f.agent), false);
  assert.equal(existsSync(f.env.TEST_LOG), false);
});
test('missing settings skips before tool resolution', t => {
  const f = fixture(t);
  rmSync(join(f.agent, 'settings.json'));
  f.env.TEST_RESOLVE_EXIT = '28';
  assert.equal(run(f).status, 0);
  assert.equal(existsSync(f.env.TEST_LOG), false);
});
test('missing payload is skipped without executing Node', t => {
  const f = fixture(t);
  rmSync(join(f.pkg, 'bin/pi'));
  assert.equal(run(f).status, 0);
  assert.equal(existsSync(f.env.TEST_LOG), false);
});
test('resolution failures propagate', t => {
  const f = fixture(t);
  f.env.TEST_RESOLVE_EXIT = '28';
  assert.equal(run(f).status, 28);
  assert.equal(existsSync(f.env.TEST_LOG), false);
});
test('updater failures propagate', t => {
  const f = fixture(t);
  f.env.TEST_PI_EXIT = '37';
  assert.equal(run(f).status, 37);
});
test('custom agent never falls back to an initialized default agent', t => {
  const f = fixture(t);
  f.env.PI_CODING_AGENT_DIR = join(f.root, 'missing custom agent');
  assert.equal(run(f).status, 0);
  assert.equal(existsSync(f.env.PI_CODING_AGENT_DIR), false);
  assert.equal(existsSync(f.env.TEST_LOG), false);
});
