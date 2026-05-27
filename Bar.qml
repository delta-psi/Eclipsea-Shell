
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import Quickshell.Io

Variants {
  id: root 
  model: Quickshell.screens

  property bool barVisible: true

  delegate: PanelWindow {
    id: mainBar
    visible: root.barVisible
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "quickshell-bar"
    required property var modelData
    screen: modelData

    anchors {
      top: true
      left: true
      bottom: true
    }

    implicitWidth: 50
    // color: "#1a1b26"
    color: "transparent"

    property int pageOffset: {
      const active = Hyprland.focusedWorkspace?.id ?? 1 
      return Math.floor((active - 1) / 5) * 5
    }

    Rectangle {
      anchors {
        top: parent.top 
        topMargin: 10
        bottom: parent.bottom 
        left: parent.left 
        right: parent.right 
      }
      // color: "#1a1b26"
      color: "transparent"

      ColumnLayout {
        anchors {
          fill: parent 
        }

        Text {
          text: ""
          font.pixelSize: 24
          font.family: "JetBrainsMono Nerd Font"
          color: "#7EB3E6"
          Layout.alignment: Qt.AlignHCenter 
        }
        Rectangle {
          Layout.alignment: Qt.AlignHCenter 
          Layout.topMargin: 4 
          implicitWidth: 34
          implicitHeight: workspaceColumn.implicitHeight + 16
          radius: width / 2 
          color: "#16161e"
          clip: true 

          Column {
            id: workspaceColumn 
            anchors.centerIn: parent 
            spacing: 6 
            Repeater {
              model: 5 
              Item {
                width: 26 
                height: 26 

                property int wsId: index + 1 + mainBar.pageOffset 
                property var ws: Hyprland.workspaces.values.find(w => w.id === wsId)
                property bool isActive: Hyprland.focusedWorkspace?.id === wsId

                Rectangle {
                  anchors.centerIn: parent
                  width: 24 
                  height: 24 
                  radius: width / 2 
                  // color: "transparent"
                  // color: parent.isActive ? "#0db9d7" : (ws ? "#7aa2f7" : "#444b6a")
                  color: "#0db9d7"
                  // border.color: "#0db9d7"
                  // border.width: 2 
                  visible: parent.isActive
                }

                Text {
                  anchors.centerIn: parent 
                  text: isActive ? "󰮯" : (ws ? "" : "" )
                  // color: isActive ? "#0db9d7" : (ws ? "#7aa2f7" : "#444b6a") # #1a1b26
                  color: isActive ? "#1a1b26" : (ws ? "#7aa2f7" : "#444b6a") 
                  font { pixelSize: 18; bold: true }
                }

                MouseArea {
                  anchors.fill: parent 
                    onClicked: Hyprland.dispatch("workspace " + wsId)
                }
              }
            }
          }
        }
        Item { Layout.fillHeight: true }
      }
    }
  }
}
