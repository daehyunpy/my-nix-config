local wezterm = require("wezterm")

local function get_appearance()
    if wezterm.gui then
        return wezterm.gui.get_appearance()
    end
    return "Dark"
end

local function scheme_for_appearance(appearance)
    if appearance:find "Dark" then
        return "GitHub Dark"
    else
        return "Github"
    end
end

return {
    font = wezterm.font("ZedMono Nerd Font"),
    color_scheme = scheme_for_appearance(get_appearance()),
    quit_when_all_windows_are_closed = false,
}
