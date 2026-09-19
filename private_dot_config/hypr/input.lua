-- Fcitx5-Rime owns CapsLock as the Chinese/English toggle.
-- Map the physical key to Menu instead of Caps_Lock so it never changes the
-- hardware capitalization lock state. Rime consumes Menu in its processor.
hl.config({
  input = {
    kb_options = "caps:menu",
  },
})

-- Use the Mac-style Alt/Super positions only on the built-in HP keyboard.
-- External keyboards keep the global mapping above.
hl.device({
  name = "at-translated-set-2-keyboard",
  kb_options = "caps:menu,altwin:swap_alt_win",
})
