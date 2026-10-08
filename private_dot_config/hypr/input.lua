-- Rime handles the Shift language toggle. Restore ordinary CapsLock instead
-- of Omarchy's compose key or the previous CapsLock-to-Menu mapping.
hl.config({
  input = {
    kb_options = "",
  },
})

-- Use the Mac-style Alt/Super positions only on the built-in HP keyboard.
-- External keyboards keep the standard mapping above.
hl.device({
  name = "at-translated-set-2-keyboard",
  kb_options = "altwin:swap_alt_win",
})
