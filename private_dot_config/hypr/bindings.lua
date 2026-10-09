-- Move screenshot from Omarchy's default PRINT binding to ALT+A.
hl.unbind("PRINT")
hl.unbind("ALT + A")
o.bind("ALT + A", "Screenshot", "omarchy-capture-screenshot")

-- Move the clipboard manager from Omarchy's default SUPER+CTRL+V binding.
-- SUPER+SHIFT+C is a default Calendar binding, so unbind it before replacing it.
hl.unbind("SUPER + SHIFT + C")
hl.unbind("SUPER + CTRL + V")
o.bind("SUPER + SHIFT + C", "Clipboard manager", "omarchy-shell shell toggle omarchy.clipboard")

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
