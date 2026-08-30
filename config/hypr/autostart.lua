-- Extra autostart processes.
-- Load Window Minimize CSD Button Interceptor Hook
local hook_so = (os.getenv("HOME") or "/home/azterisk") .. "/.config/omarchy/plugins/azterisk.minimize/hyprland-plugin/minimize-hook.so"
o.exec_on_start("hyprctl plugin load " .. hook_so)
