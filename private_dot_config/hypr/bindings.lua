-- Move screenshot from Omarchy's default PRINT binding to SUPER+A.
hl.unbind("PRINT")
o.bind("SUPER + A", "Screenshot", "omarchy-capture-screenshot")

-- Move universal copy/paste/cut to ALT+C/ALT+V/ALT+X so they sit where macOS has
-- Command+C/Command+V/Command+X, next to the window bindings that use the macOS
-- Option position. Omarchy keeps its equivalents as local functions in
-- default/hypr/bindings/clipboard.lua, so the logic is repeated here. The
-- terminal branch matters: CTRL+C is SIGINT and CTRL+V is literal-next in a
-- terminal, so terminals get the Insert chords instead.
local function send_shortcut_once(mods, key)
  return function()
    hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "down" }))

    hl.timer(function()
      hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "up" }))
    end, { timeout = 50, type = "oneshot" })
  end
end

-- Use the terminal tag from default/hypr/apps/terminals.lua; dynamic tags carry
-- a trailing "*".
local function active_window_is_terminal()
  local window = hl.get_active_window()
  if not window then
    return false
  end

  for _, tag in ipairs(window.tags or {}) do
    if tag:gsub("%*$", "") == "terminal" then
      return true
    end
  end

  return false
end

local function universal_clipboard_shortcut(default_mods, default_key, terminal_mods, terminal_key)
  return function()
    if active_window_is_terminal() then
      send_shortcut_once(terminal_mods, terminal_key)()
    else
      send_shortcut_once(default_mods, default_key)()
    end
  end
end

hl.unbind("SUPER + C")
hl.unbind("SUPER + V")
hl.unbind("SUPER + X")
o.bind("ALT + C", "Universal copy", universal_clipboard_shortcut("CTRL", "C", "CTRL", "Insert"))
o.bind("ALT + V", "Universal paste", universal_clipboard_shortcut("CTRL", "V", "SHIFT", "Insert"))
o.bind("ALT + X", "Universal cut", send_shortcut_once("CTRL", "X"))

-- Move the clipboard history to ALT+SHIFT+V, matching the Paste app's
-- Command+Shift+V on macOS. The unbinds keep Omarchy's default SUPER+CTRL+V
-- binding and its default Calendar webapp off the keys we took over.
hl.unbind("SUPER + SHIFT + C")
hl.unbind("SUPER + CTRL + V")
o.bind("ALT + SHIFT + V", "Clipboard manager", "omarchy-shell shell toggle omarchy.clipboard")

-- These retained app/TUI bindings are restored explicitly because
-- `omarchy remove preinstalls` disables the default preinstall binding block.
hl.unbind("SUPER + CTRL + RETURN")
hl.unbind("SUPER + SHIFT + D")
hl.unbind("SUPER + SHIFT + W")
o.bind("SUPER + CTRL + RETURN", "Herdr", { omarchy = "terminal-herdr" })
o.bind("SUPER + SHIFT + D", "Docker", { tui = "omarchy-launch-docker-tui" })
o.bind("SUPER + SHIFT + W", "Omawrite", { launch = "omawrite" })

-- Use SUPER+Q to close the active window instead of the default SUPER+W.
hl.unbind("SUPER + W")
o.bind("SUPER + Q", "Close window", hl.dsp.window.close())

-- Unify window navigation with the macOS layout: directional focus on
-- SUPER + HJKL, directional movement on SUPER + SHIFT + HJKL. This works
-- because input.lua no longer swaps Alt/Super, so the physical Super key sits
-- where macOS has Option.
--
-- SUPER + J/K/L already hold Omarchy defaults, so free them first. SUPER + H
-- was unused.
hl.unbind("SUPER + J")
hl.unbind("SUPER + K")
hl.unbind("SUPER + L")

-- The Omarchy defaults displaced out of the SUPER + HJKL block.
o.bind("ALT + J", "Toggle window split", hl.dsp.layout("togglesplit"))
o.bind("ALT + K", "Keybindings", "omarchy-menu-keybindings")
o.bind("ALT + L", "Toggle workspace layout", "omarchy-hyprland-workspace-layout-toggle")

o.bind("SUPER + H", "Focus on left window", hl.dsp.focus({ direction = "l" }))
o.bind("SUPER + J", "Focus on below window", hl.dsp.focus({ direction = "d" }))
o.bind("SUPER + K", "Focus on above window", hl.dsp.focus({ direction = "u" }))
o.bind("SUPER + L", "Focus on right window", hl.dsp.focus({ direction = "r" }))

-- window.move keeps the scrolling layout's column semantics: moving sideways
-- consumes the window into the neighbouring column (stacking the two), while up
-- and down reorder it inside its own column.
o.bind("SUPER + SHIFT + H", "Move window left", hl.dsp.window.move({ direction = "l" }))
o.bind("SUPER + SHIFT + J", "Move window down", hl.dsp.window.move({ direction = "d" }))
o.bind("SUPER + SHIFT + K", "Move window up", hl.dsp.window.move({ direction = "u" }))
o.bind("SUPER + SHIFT + L", "Move window right", hl.dsp.window.move({ direction = "r" }))

-- Move the launcher to ALT+SPACE, matching Raycast on Command+Space. ALT+SPACE
-- was unused; SUPER+SPACE (Omarchy menu) and SUPER+ALT+SPACE (Apps menu) are
-- unbound so the defaults cannot shadow the new key on the freed modifiers.
hl.unbind("SUPER + SPACE")
hl.unbind("SUPER + ALT + SPACE")
o.bind("ALT + SPACE", "Omarchy menu", "omarchy-menu toggle")
