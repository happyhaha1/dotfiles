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
