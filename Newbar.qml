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

  property var specialWorkspaces: ({
    "idle":          "󰒲",
    "systemStats":   "󰍛",
    "clock":         "󰥔",
    "music":         "󰎆",
    "communication": "󰍦",
    "todolist":      "󰄳"
  })

  delegate: PanelWindow {
    id: mainBar
    visible: root.barVisible
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "quickshell-bar"
    // WlrLayershell.blur: true
    BackgroundEffect.blurRegion: Region { item: root.content }
    required property var modelData
    screen: modelData

    anchors {
      top: true
      left: true
      bottom: true
    }

    implicitWidth: 50
    color: "transparent"

    property int pageOffset: {
      const active = Hyprland.focusedWorkspace?.id ?? 1
      return Math.floor((active - 1) / 5) * 5
    }

    // Ordered list of open special workspace names, in open order.
    // e.g. ["music", "clock"] if music was opened first.
    property var openSpecials: []

    // Whether any special workspace is currently visible
    property bool specialActive: openSpecials.length > 0

    // The focused special name (null if a normal ws is focused)
    property string focusedSpecial: {
      const focused = Hyprland.focusedWorkspace
      if (focused && focused.id < 0) {
        return (focused.name ?? "").replace(/^special:/, "")
      }
      return ""
    }

    // Watch the full workspace list for special workspaces appearing/disappearing
    Connections {
      target: Hyprland
      function onWorkspacesChanged() {
        const currentSpecials = Hyprland.workspaces.values
          .filter(w => w.id < 0)
          .map(w => w.name.replace(/^special:/, ""))

        // Add any newly appeared specials to the end (preserving open order)
        const updated = [...mainBar.openSpecials]
        for (const name of currentSpecials) {
          if (!updated.includes(name)) {
            updated.push(name)
          }
        }

        // Remove any that have since closed
        const filtered = updated.filter(name => currentSpecials.includes(name))

        mainBar.openSpecials = filtered
      }
    }

    Rectangle {
      anchors {
        top: parent.top
        topMargin: 10
        bottom: parent.bottom
        left: parent.left
        right: parent.right
      }
      color: "transparent"

      ColumnLayout {
        anchors.fill: parent

        Text {
          text: ""
          font.pixelSize: 24
          font.family: "JetBrainsMono Nerd Font"
          color: "#7EB3E6"
          Layout.alignment: Qt.AlignHCenter
        }

        Rectangle {
          id: pill
          Layout.alignment: Qt.AlignHCenter
          Layout.topMargin: 4
          implicitWidth: 34
          implicitHeight: pillContent.implicitHeight + 16
          radius: width / 2
          color: "#16161e"
          clip: true

          // Normal 1–5 workspace dots — always rendered so the pill never resizes
          Column {
            id: pillContent
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
                  color: "transparent"
                  border.color: "#0db9d7"
                  border.width: 2
                  visible: parent.isActive
                }

                Text {
                  anchors.centerIn: parent
                  text: parent.isActive ? "󰮯" : (parent.ws ? "" : "")
                  color: parent.isActive ? "#0db9d7" : (parent.ws ? "#7aa2f7" : "#444b6a")
                  font { pixelSize: 18; bold: true }
                }

                MouseArea {
                  anchors.fill: parent
                  onClicked: Hyprland.dispatch("workspace " + wsId)
                }
              }
            }
          }

          // Special workspace overlay — sits pixel-perfectly on top of pillContent
          // and uses the same Item size + spacing so icons land on the same slots
          Column {
            id: specialOverlay

            // Mirror pillContent's anchoring exactly
            anchors.centerIn: parent
            spacing: 6

            visible: mainBar.specialActive
            opacity: visible ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 180 } }

            Repeater {
              model: 5
              Item {
                width: 26
                height: 26

                // Which special (if any) occupies this slot (0-indexed)
                property string specialName: index < mainBar.openSpecials.length
                                              ? mainBar.openSpecials[index]
                                              : ""
                property bool hasSpecial: specialName !== ""
                property bool isFocused: hasSpecial && specialName === mainBar.focusedSpecial

                // Tinted background so the normal dot beneath is obscured
                Rectangle {
                  anchors.fill: parent
                  radius: width / 2
                  // Match the pill background to cleanly cover the dot below
                  color: parent.hasSpecial ? "#16161e" : "transparent"
                }

                // Focused ring
                Rectangle {
                  anchors.centerIn: parent
                  width: 24
                  height: 24
                  radius: width / 2
                  color: "transparent"
                  border.color: "#0db9d7"
                  border.width: 2
                  visible: parent.isFocused
                }

                // Special workspace icon
                Text {
                  anchors.centerIn: parent
                  text: parent.hasSpecial
                        ? (root.specialWorkspaces[parent.specialName] ?? "󰘬")
                        : ""
                  font.pixelSize: 18
                  font.bold: true
                  font.family: "JetBrainsMono Nerd Font"
                  color: parent.isFocused ? "#0db9d7" : "#7aa2f7"
                }

                MouseArea {
                  anchors.fill: parent
                  enabled: parent.hasSpecial
                  onClicked: Hyprland.dispatch("togglespecialworkspace " + parent.specialName)
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
