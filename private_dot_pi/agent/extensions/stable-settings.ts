// Keep Pi's changelog marker stable so it does not create dotfiles noise.
// See https://github.com/earendil-works/pi/issues/720.

import { readFileSync, writeFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

const STABLE_CHANGELOG_VERSION = "99.99.99";

export default function (pi: any) {
  pi.on("session_start", async () => {
    const settingsPath = join(homedir(), ".pi", "agent", "settings.json");

    try {
      const original = readFileSync(settingsPath, "utf8");
      const settings = JSON.parse(original);
      settings.lastChangelogVersion = STABLE_CHANGELOG_VERSION;
      const updated = `${JSON.stringify(settings, null, 2)}\n`;

      if (updated !== original) {
        writeFileSync(settingsPath, updated, "utf8");
      }
    } catch {
      // A settings marker must never prevent Pi from starting.
    }
  });
}
