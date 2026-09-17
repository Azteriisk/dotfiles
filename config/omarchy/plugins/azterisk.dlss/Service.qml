import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: root

  property var shell: null

  readonly property string home: Quickshell.env("HOME")
  readonly property string scriptPath: home + "/.local/bin/omarchy-dlss"

  property int activeCount: 0
  property int totalCompatible: 0
  property var gamesList: []
  property bool isScanning: false

  signal statusUpdated()

  function refresh() {
    if (scanProcess.running) return
    isScanning = true
    scanProcess.running = true
  }

  function openGui() {
    Quickshell.execDetached("omarchy-dlss", ["gui"])
  }

  Process {
    id: scanProcess
    command: [root.scriptPath, "json"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        root.isScanning = false
        try {
          var parsed = JSON.parse(text.trim())
          if (Array.isArray(parsed)) {
            root.gamesList = parsed
            var active = 0
            var compat = 0
            for (var i = 0; i < parsed.length; i++) {
              if (parsed[i].dlss5_active) active++
              if (parsed[i].compatible) compat++
            }
            root.activeCount = active
            root.totalCompatible = compat
            root.statusUpdated()
          }
        } catch(e) {}
      }
    }
  }

  Timer {
    id: startupTimer
    interval: 2500
    running: true
    repeat: false
    onTriggered: root.refresh()
  }

  Timer {
    id: periodicTimer
    interval: 180000
    running: true
    repeat: true
    onTriggered: root.refresh()
  }
}
