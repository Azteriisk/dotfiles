import QtQuick
import Quickshell
import qs.Commons
import qs.Ui

BarIconButton {
  id: root
  property string moduleName: "azterisk.dlss"

  readonly property var dlssService: bar?.shell?.serviceFor("azterisk.dlss")
  property bool popupOpen: false

  function close() {
    root.popupOpen = false
  }

  active: dlssService ? (dlssService.activeCount > 0) : false
  text: "󱚤"
  tooltipText: "DLSS 5 Neural Rendering (" + (dlssService ? dlssService.activeCount : 0) + " active games)\nLeft-click: Open DLSS 5 Manager\nRight-click: Quick Status"

  onPressed: function(button) {
    if (button === Qt.RightButton) {
      root.popupOpen = !root.popupOpen
    } else {
      if (dlssService) {
        dlssService.openGui()
      } else {
        Quickshell.execDetached("omarchy-dlss", ["gui"])
      }
    }
  }

  PopupCard {
    id: dlssPopup
    anchorItem: root
    bar: root.bar
    owner: root
    open: root.popupOpen
    margin: Style.space(12)
    padding: Style.space(18)
    contentWidth: dlssPopup.fittedContentWidth(Style.space(320))
    contentHeight: dlssPopup.fittedContentHeight(contentWrapper.implicitHeight)

    Item {
      id: contentWrapper
      anchors.fill: parent
      anchors.margins: Style.space(6)
      implicitHeight: contentColumn.implicitHeight + Style.space(12)

      Column {
        id: contentColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Style.space(12)

        // Header Row
        Row {
          width: parent.width
          spacing: Style.space(10)

          Text {
            text: "󱚤"
            color: Color.accent
            font.family: Style.font.family
            font.pixelSize: Style.font.title
            anchors.verticalCenter: parent.verticalCenter
          }

          Column {
            width: parent.width - Style.space(50)
            anchors.verticalCenter: parent.verticalCenter

            Text {
              text: "DLSS 5 Neural Rendering"
              color: Color.foreground
              font.family: Style.font.family
              font.pixelSize: Style.font.subtitle
              font.bold: true
            }

            Text {
              text: (dlssService ? dlssService.activeCount : 0) + " active profiles • " + (dlssService ? dlssService.totalCompatible : 0) + " compatible"
              color: Qt.darker(Color.foreground, 1.3)
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
            }
          }
        }

        PanelSeparator { strength: 0.2 }

        // Action Buttons
        Column {
          width: parent.width
          spacing: Style.space(8)

          Button {
            width: parent.width
            text: "Open DLSS 5 Manager"
            iconText: "󰒓"
            onClicked: {
              root.popupOpen = false
              if (dlssService) dlssService.openGui()
            }
          }

          Button {
            width: parent.width
            text: "Rescan Steam Libraries"
            iconText: "󰑐"
            onClicked: {
              if (dlssService) dlssService.refresh()
            }
          }
        }
      }
    }
  }
}
