-- Hyprland Monitor Configuration
-- Managed by Display Manager
local omarchy_gdk_scale = 1
local omarchy_monitor_scale = "auto"

hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))

-- Display 1: HDMI-A-1
hl.monitor({
  output = "HDMI-A-1",
  mode = "1920x1080@60",
  position = "169x1080",
  scale = 1.25,
  transform = 0,
})

-- Display 2: DP-1 (Primary)
hl.monitor({
  output = "DP-1",
  mode = "1920x1080@240",
  position = "0x0",
  scale = 1,
  transform = 0,
})

-- Fallback for any other connected displays
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

-- Workspace & Display Numbering Assignment
hl.config({
  workspace = {
    "1, monitor:DP-1, default:true",
    "2, monitor:HDMI-A-1, default:true",
    "3, monitor:DP-1",
    "4, monitor:HDMI-A-1",
    "5, monitor:DP-1",
    "6, monitor:HDMI-A-1",
    "7, monitor:DP-1",
    "8, monitor:HDMI-A-1",
    "9, monitor:DP-1",
    "10, monitor:HDMI-A-1",
  },
})
