-- Toggle Rime's Chinese/ASCII mode with CapsLock.
-- Consume both events so CapsLock does not also change the hardware lock state.

local M = {}

local function is_language_toggle_key(key_repr)
    -- Hyprland's caps:menu XKB option turns physical CapsLock into Menu.
    return key_repr == "Menu"
end

function M.func(key, env)
    local context = env.engine.context

    if key:release() then
        if is_language_toggle_key(key:repr()) then
            return 1 -- kAccepted: consume the release as well
        end
        return 2 -- kNoop
    end

    if is_language_toggle_key(key:repr())
        and not (key:ctrl() or key:alt() or key:super()) then
        if context:is_composing() then
            context:commit()
        end
        context:set_option("ascii_mode", not context:get_option("ascii_mode"))
        return 1 -- kAccepted: do not toggle hardware CapsLock
    end

    return 2 -- kNoop
end

return M
