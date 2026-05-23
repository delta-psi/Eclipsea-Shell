
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

    // Ethernet state 
    property bool ethernetConnected: false
    property string ethernetIp: ""
    property string ethernetDevice: ""
    property string nmcliBuffer: ""

    Process {
      id: nmcliProc
      // command: ["nmcli", "-t", "-f", "TYPE,STATE,CONNECTION,IP4ADDRESS", "device"]
      command: ["nmcli", "-t", "-f", "GENERAL.STATE", "GENERAL.CONNECTION", "IP4.ADDRESS", "dev", "show", "enp34s0"]

      stdout: SplitParser {
        onRead: data => {
          mainBar.nmcliBuffer += data
        }
      }

      onRunningChanged: {
        if (!running) {
          const lines = mainBar.nmcliBuffer .trim().split("\n")
          mainBar.nmcliBuffer = ""

          let connected = false
          let ip = ""
          let conn = ""

          for (const line of lines) {
            // Each line is "FIELD:value" — split on first colon only
            const colon = line.indexOf(":")
            if (colon === -1) continue
            const field = line.substring(0, colon).trim()
            const value = line.substring(colon + 1).trim()

            if (field === "GENERAL.STATE") {
              // Value looks like "100 (connected)" or "20 (unavailable)"
              connected = value.includes("connected") &&
                          !value.includes("disconnected")
            } else if (field === "GENERAL.CONNECTION") {
              conn = value
            } else if (field === "IP4.ADDRESS[1]") {
              // Value is "192.168.x.x/24" — strip prefix length
              ip = value.split("/")[0]
            }
          }

          mainBar.ethernetConnected = connected
          mainBar.ethernetIp = ip
          mainBar.ethernetDevice = conn

        }
      }
      // running: true
      // stdout: SplitParser {
      //   onRead: data => {
      //     // Reset before re-parsing
      //     mainBar.ethernetConnected = false
      //     mainBar.ethernetIp = ""
      //     mainBar.ethernetDevice = ""
      //
      //     const lines = data.trim().split("\n")
      //     for (const line of lines) {
      //       const parts = line.split(":")
      //       // parts: [type, state, connection, ip4]
      //       if (parts[0] === "ethernet" && parts[1] === "connected") {
      //         mainBar.ethernetConnected = true
      //         mainBar.ethernetDevice = parts[2] ?? ""
      //         // IP comes as "192.168.1.x/24" — strip the prefix length
      //         mainBar.ethernetIp = (parts[3] ?? "").split("/")[0]
      //         break
      //       }
      //     }
      //   }
      // }
    }

    // Poll nmcli every 10 seconds to catch cable plug/unplug
    Timer {
      interval: 10000
      running: true
      repeat: true
      onTriggered: nmcliProc.running = true
    } // end of widget

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

              // Text {
              //   Layout.alignment: Qt.AlignHCenter 
              //   property int wsId: index + 1 + mainBar.pageOffset 
              //   property var ws: Hyprland.workspaces.values.find(w => w.id === wsId)
              //   property bool isActive: Hyprland.focusedWorkspace?.id === wsId
              //   text: isActive ? "󰮯" : (ws ? "" : "" )
              //   color: isActive ? "#0db9d7" : (ws ? "#7aa2f7" : "#444b6a")
              //   font { pixelSize: 18; bold: true }
              //   MouseArea {
              //     anchors.fill: parent
              //     onClicked: Hyprland.dispatch("workspace " + wsId)
              //   }
              // }
              }
            }
          }
        }
        Item { Layout.fillHeight: true }

        // ── Widget pill ──────────────────────────────────────────────
        Item {
          Layout.alignment: Qt.AlignHCenter
          Layout.bottomMargin: 4
          // Give enough width for pill + tooltip to both be hittable
          implicitWidth: widgetPill.implicitWidth
          implicitHeight: widgetPill.implicitHeight

          // Tooltip — lives here in the unclipped Item
          Rectangle {
            id: ethTooltip
            visible: ethernetMouse.containsMouse && mainBar.ethernetConnected
            // Anchor to the right edge of the pill with a small gap
            x: widgetPill.width + 8
            y: widgetPill.height - height  // bottom-align with pill
            width: ethTooltipText.implicitWidth + 16
            height: ethTooltipText.implicitHeight + 10
            radius: 6
            color: "#16161e"
            border.color: "#7aa2f7"
            border.width: 1
            z: 10

            Text {
              id: ethTooltipText
              anchors.centerIn: parent
              text: (mainBar.ethernetDevice !== "" ? mainBar.ethernetDevice + "\n" : "")
                    + (mainBar.ethernetIp !== "" ? mainBar.ethernetIp : "No IP")
              font { pixelSize: 10; family: "JetBrainsMono Nerd Font" }
              color: "#c0caf5"
              horizontalAlignment: Text.AlignHCenter
            }
          }

          // The pill itself — clipped for visuals only
          Rectangle {
            id: widgetPill
            implicitWidth: 34
            implicitHeight: widgetColumn.implicitHeight + 16
            radius: width / 2
            color: "#16161e"
            clip: true

            Column {
              id: widgetColumn
              anchors.centerIn: parent
              spacing: 6

              // ── Ethernet ─────────────────────────────────────────
              Item {
                id: ethernetWidget
                width: 26
                height: 26

                Text {
                  anchors.centerIn: parent
                  text: mainBar.ethernetConnected ? "󰈀" : "󰈁"
                  font { pixelSize: 18; bold: true; family: "JetBrainsMono Nerd Font" }
                  color: mainBar.ethernetConnected ? "#7aa2f7" : "#444b6a"
                }

                Process {
                  id: ethConnect 
                  command: ["nmcli", "device", "connect", "enp34s0"]
                }

                Process {
                  id: ethDisconnect
                  command: ["nmcli", "device", "disconnect", "enp34s0"]
                }

                MouseArea {
                  id: ethernetMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  onClicked: {
                    if (mainBar.ethernetConnected)
                      ethDisconnect.running = true 
                    else 
                      ethConnect.running = true
                    // Process {
                    //   command: mainBar.ethernetConnected
                    //     ? ["nmcli", "device", "disconnect", "enp34s0"]
                    //     : ["nmcli", "device", "connect",    "enp34s0"]
                    //   running: true
                    // }
                    refreshTimer.start()
                  }
                }

                Timer {
                  id: refreshTimer
                  interval: 1500
                  onTriggered: nmcliProc.running = true
                }
              }

              // ── Bluetooth stub ───────────────────────────────────
              Item {
                width: 26
                height: 26

                Text {
                  anchors.centerIn: parent
                  text: "󰂲"
                  font { pixelSize: 18; bold: true; family: "JetBrainsMono Nerd Font" }
                  color: "#444b6a"
                }

                MouseArea {
                  anchors.fill: parent
                  onClicked: {}
                }
              }
            }
          }
        }
        // Rectangle {
        //   id: widgetPill
        //   Layout.alignment: Qt.AlignHCenter
        //   Layout.bottomMargin: 4
        //   implicitWidth: 34
        //   implicitHeight: widgetColumn.implicitHeight + 16
        //   radius: width / 2
        //   color: "#16161e"
        //   clip: true
        //
        //   Column {
        //     id: widgetColumn
        //     anchors.centerIn: parent
        //     spacing: 6
        //
        //     // ── Ethernet widget ──────────────────────────────────────
        //     Item {
        //       id: ethernetWidget
        //       width: 26
        //       height: 26
        //
        //       // Tooltip showing IP on hover
        //       property bool hovered: ethernetMouse.containsMouse
        //
        //       Rectangle {
        //         id: tooltip
        //         visible: ethernetWidget.hovered && mainBar.ethernetConnected
        //         // Position to the right of the pill
        //         x: widgetPill.width + 6
        //         y: (parent.height - height) / 2
        //         width: tooltipText.implicitWidth + 16
        //         height: tooltipText.implicitHeight + 10
        //         radius: 6
        //         color: "#16161e"
        //         border.color: "#7aa2f7"
        //         border.width: 1
        //         // Escape clipping so it appears outside the pill
        //         parent: widgetPill.parent
        //
        //         Text {
        //           id: tooltipText
        //           anchors.centerIn: parent
        //           text: mainBar.ethernetDevice !== ""
        //                 ? mainBar.ethernetDevice + "\n" + mainBar.ethernetIp
        //                 : mainBar.ethernetIp
        //           font { pixelSize: 10; family: "JetBrainsMono Nerd Font" }
        //           color: "#c0caf5"
        //           horizontalAlignment: Text.AlignHCenter
        //         }
        //       }
        //
        //       // Ethernet icon — changes by state
        //       Text {
        //         anchors.centerIn: parent
        //         text: mainBar.ethernetConnected ? "󰈀" : "󰈁"
        //         font { pixelSize: 18; bold: true; family: "JetBrainsMono Nerd Font" }
        //         color: mainBar.ethernetConnected ? "#7aa2f7" : "#444b6a"
        //       }
        //
        //       MouseArea {
        //         id: ethernetMouse
        //         anchors.fill: parent
        //         hoverEnabled: true
        //         onClicked: {
        //           // Toggle the first ethernet device found
        //           const cmd = mainBar.ethernetConnected
        //             ? ["nmcli", "networking", "off"]
        //             : ["nmcli", "networking", "on"]
        //           Qt.createQmlObject(
        //             'import Quickshell.Io; Process { command: ' +
        //             JSON.stringify(cmd) + '; running: true }',
        //             mainBar, "toggleEth"
        //           )
        //           // Refresh state shortly after toggling
        //           refreshTimer.start()
        //         }
        //       }
        //
        //       Timer {
        //         id: refreshTimer
        //         interval: 1500
        //         onTriggered: nmcliProc.running = true
        //       }
        //     }
        //
        //     // ── Bluetooth stub (wire up when bluez is available) ─────
        //     Item {
        //       id: bluetoothWidget
        //       width: 26
        //       height: 26
        //
        //       Text {
        //         anchors.centerIn: parent
        //         // 󰂲 = bt off, 󰂯 = bt on — swap when you add bluez support
        //         text: "󰂲"
        //         font { pixelSize: 18; bold: true; family: "JetBrainsMono Nerd Font" }
        //         color: "#444b6a"
        //       }
        //
        //       MouseArea {
        //         anchors.fill: parent
        //         // No-op until bluez is available
        //         onClicked: {}
        //       }
        //     }
        //   }
        // } // end of widgets
      }
    }
  }
  // }
}
