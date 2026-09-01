-- Fcitx5-Rime owns CapsLock as the Chinese/English toggle.
-- Map the physical key to Menu instead of Caps_Lock so it never changes the
-- hardware capitalization lock state. Rime consumes Menu in its processor.
hl.config({
  input = {
    kb_options = "caps:menu",
  },
})
