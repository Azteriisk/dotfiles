import QtQuick
import Quickshell
import qs.Commons
import qs.Ui

BarIndicator {
  id: root

  readonly property var idleService: bar?.shell?.serviceFor("azterisk.idle") || bar?.shell?.firstPartyServiceFor("omarchy.idle")

  property bool popupOpen: false

  function close() {
    root.popupOpen = false
  }

  active: idleService ? idleService.stayAwake : false
  activeText: "󰅶"
  inactiveText: "󰅶"
  activeTooltipText: idleService && idleService.stayAwakeAllowsScreensaver
    ? "Stay Awake: Active (Screensaver Enabled, Lock Inactive)\nLeft-click: Toggle off | Right-click: Settings"
    : "Stay Awake: Active (Screensaver & Lock Inactive)\nLeft-click: Toggle off | Right-click: Settings"
  inactiveTooltipText: "Stay Awake: Inactive (Normal Idle & Lock)\nLeft-click: Toggle on | Right-click: Settings"

  function toggle() {
    if (root.idleService) root.idleService.setIdleEnabled(root.active)
  }

  onPressed: function(button) {
    if (button === Qt.RightButton) {
      root.popupOpen = !root.popupOpen
    } else {
      root.toggle()
    }
  }

  PopupCard {
    id: settingsPopup
    anchorItem: root
    bar: root.bar
    owner: root
    open: root.popupOpen
    contentWidth: settingsPopup.fittedContentWidth(Style.space(320))
    contentHeight: settingsPopup.fittedContentHeight(contentColumn.implicitHeight)
    padding: Style.spacing.cardPadding

    Column {
      id: contentColumn
      width: parent.width
      spacing: Style.space(12)

      // Header Row
      Row {
        width: parent.width
        spacing: Style.space(8)

        Text {
          text: "󰅶"
          color: root.active ? (root.bar ? root.bar.urgent : Color.urgent) : Color.foreground
          font.family: Style.font.family
          font.pixelSize: Style.font.subtitle
          anchors.verticalCenter: parent.verticalCenter
        }

        Text {
          text: "Stay Awake & Idle"
          color: Color.foreground
          font.family: Style.font.family
          font.pixelSize: Style.font.subtitle
          font.bold: true
          anchors.verticalCenter: parent.verticalCenter
          width: parent.width - Style.space(90)
        }

        BorderSurface {
          anchors.verticalCenter: parent.verticalCenter
          height: Style.space(22)
          width: Style.space(62)
          radius: Style.cornerRadius
          color: root.active ? Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.2) : Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.1)
          borderSpec: Border.controlSpec("normal", Color.foreground, Color.accent)

          Text {
            anchors.centerIn: parent
            text: root.active ? "ACTIVE" : "OFF"
            color: root.active ? Color.accent : Qt.darker(Color.foreground, 1.4)
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
            font.bold: true
          }
        }
      }

      PanelSeparator { strength: 0.15 }

      // Master Toggle
      Toggle {
        width: parent.width
        label: "Stay Awake Mode"
        description: root.active ? "System lock is currently disabled" : "Normal idle and lock timeouts active"
        checked: root.active
        onClicked: root.toggle()
      }

      // Stay Awake Behavior
      Column {
        width: parent.width
        spacing: Style.space(6)

        PanelSectionHeader {
          text: "STAY AWAKE BEHAVIOR"
        }

        ButtonGroup {
          width: parent.width
          value: root.idleService ? root.idleService.stayAwakeMode : "screensaver-only"
          options: [
            {
              value: "screensaver-only",
              label: "Screensaver",
              icon: "󱄄",
              tooltip: "Show screensaver on idle, but never lock PC"
            },
            {
              value: "full",
              label: "Inhibit All",
              icon: "󰅶",
              tooltip: "Keep screen completely awake (no screensaver, no lock)"
            }
          ]
          onChanged: function(val) {
            if (root.idleService) root.idleService.setStayAwakeMode(val)
          }
        }
      }

      // Screensaver Timeout
      Column {
        width: parent.width
        spacing: Style.space(6)

        PanelSectionHeader {
          text: "SCREENSAVER TIMEOUT"
        }

        ButtonGroup {
          width: parent.width
          value: root.idleService && root.idleService.screensaverEnabled ? String(root.idleService.screensaverTimeoutSeconds) : "0"
          options: [
            { value: "60", label: "1m", tooltip: "Screensaver after 1 min" },
            { value: "150", label: "2.5m", tooltip: "Screensaver after 2.5 min" },
            { value: "300", label: "5m", tooltip: "Screensaver after 5 min" },
            { value: "600", label: "10m", tooltip: "Screensaver after 10 min" },
            { value: "0", label: "Off", tooltip: "Disable screensaver" }
          ]
          onChanged: function(val) {
            if (root.idleService) root.idleService.setScreensaverTimeout(Number(val))
          }
        }
      }

      // System Lock Timeout
      Column {
        width: parent.width
        spacing: Style.space(6)

        PanelSectionHeader {
          text: "NORMAL LOCK TIMEOUT"
        }

        ButtonGroup {
          width: parent.width
          value: root.idleService && root.idleService.lockTimeoutSeconds > 0 ? String(root.idleService.lockTimeoutSeconds) : "0"
          options: [
            { value: "120", label: "2m", tooltip: "Lock after 2 min idle" },
            { value: "300", label: "5m", tooltip: "Lock after 5 min idle" },
            { value: "600", label: "10m", tooltip: "Lock after 10 min idle" },
            { value: "900", label: "15m", tooltip: "Lock after 15 min idle" },
            { value: "0", label: "Never", tooltip: "Disable idle locking" }
          ]
          onChanged: function(val) {
            if (root.idleService) root.idleService.setLockTimeout(Number(val))
          }
        }
      }

      PanelSeparator { strength: 0.15 }

      // Quick Actions
      Row {
        width: parent.width
        spacing: Style.space(8)

        Button {
          width: (parent.width - Style.space(8)) / 2
          text: "Screensaver"
          iconText: "󱄄"
          tooltipText: "Launch screensaver now"
          bordered: true
          onClicked: {
            root.popupOpen = false
            if (root.bar) root.bar.run("omarchy-launch-screensaver force")
          }
        }

        Button {
          width: (parent.width - Style.space(8)) / 2
          text: "Lock Screen"
          iconText: "󰌾"
          tooltipText: "Lock PC immediately"
          bordered: true
          onClicked: {
            root.popupOpen = false
            if (root.bar) root.bar.run("omarchy-system-lock")
          }
        }
      }
    }
  }
}
