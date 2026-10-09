-- Rime handles the Shift language toggle. Restore ordinary CapsLock instead
-- of Omarchy's compose key or the previous CapsLock-to-Menu mapping.
hl.config({
  input = {
    kb_options = "",
  },
})

-- No altwin:swap_alt_win. Keys keep the label printed on them, and the
-- physical positions already line up with a Mac keyboard: the Super (Win) key
-- sits where macOS has Option and carries window management, while the Alt key
-- sits where macOS has Command and stays free for the app layer.
-- bindings.lua binds window focus/movement on SUPER + HJKL accordingly.
