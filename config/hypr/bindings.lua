-- Keep only your personal keybinding overrides here. Add new bindings or
-- unbind defaults before replacing them.

-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- To disable every Omarchy default binding, set this in
-- ~/.config/hypr/hyprland.lua before require("default.hypr.omarchy"), then add
-- only the bindings you want below:
--   omarchy_default_bindings = false

-- To disable all preinstalled app/webapp bindings, set:
--   omarchy_preinstalled_bindings = false

-- Window Minimize Plugin (azterisk.minimize)
local minimize_cmd = (os.getenv("HOME") or "/home/azterisk") .. "/.local/bin/omarchy-minimize"
o.bind("SUPER + M", "Minimize window", minimize_cmd .. " minimize")
o.bind("SUPER + ALT + M", "Restore all minimized windows", minimize_cmd .. " restore-all")
o.bind("SUPER + CTRL + M", "Restore last minimized window", minimize_cmd .. " restore-last")
o.bind("SUPER + mouse:274", "Minimize or restore on desktop click", minimize_cmd .. " mouse-action", { mouse = true })
