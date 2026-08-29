import QtQuick
import qs.Ui

BarIndicator {
  id: root

  readonly property var idleService: bar?.shell?.serviceFor("azterisk.idle") || bar?.shell?.firstPartyServiceFor("omarchy.idle")

  active: idleService ? idleService.stayAwake : false
  activeText: "󰅶"
  inactiveText: "󰅶"
  activeTooltipText: idleService && idleService.stayAwakeAllowsScreensaver
    ? "Stay Awake: Active (Screensaver Enabled, Lock Inactive)\nClick to allow normal idle lock"
    : "Stay Awake: Active (Screensaver & Lock Inactive)\nClick to allow normal idle lock"
  inactiveTooltipText: "Stay Awake: Inactive\nClick to prevent PC from locking"

  function toggle() {
    if (root.idleService) root.idleService.setIdleEnabled(root.active)
  }

  onPressed: function() { root.toggle() }
}
