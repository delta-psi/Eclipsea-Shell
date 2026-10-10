import Quickshell
import Quickshell.Wayland
import Quickshell.Io 
import QtQuick 
import QtQuick.Shapes
import qs.Theme
import qs.App_Launcher
import qs


PanelWindow {
  id: root 

  IpcHandler {
    target: "applauncher"
    function toggle() {
      AppLauncherState.toggle();
    }
  }

  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: AppLauncherState.launcherVisible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None 
  WlrLayershell.namespace: "Quickshell-Launcher"

  anchors {
    top: true 
    bottom: true 
    left: true 
    right: true 
  }

  mask: Region {
    item: AppLauncherState.launcherVisible ? maskCover : null
  }

  Item {
    id: maskCover
    anchors.fill: parent
  }

  color: "transparent"

  property string searchQuery: ""
  property int selectedIndex: 0
  readonly property bool isSelected: searchQuery.trim() !== ""
  readonly property bool isSearching: searchQuery.trim() !== ""

  property var filteredApps: {
    var q = searchQuery.trim().toLowerCase();
    var vals = DesktopEntries.applications.values;

    if (q !== "") {
      return vals.filter(function (e) {
        if (e.name.toLowerCase().indexOf(q) !== -1)
          return true;
        if (e.genericName && e.genericName.toLowerCase().indexOf(q) !== -1) 
          return true;
        for (var i = 0; i < e.keywords.length; i++)
          if (e.keywords[i].toLowerCase().indexOf(q) !== -1)
            return true;
        return false;
      }).sort(function (a, b) {
        return a.name.localeCompare(b.name);
      }); 
    }

    var recent = AppLauncherState.recentIds;
    return vals.slice().sort(function (a, b) {
      var ai = recent.indexOf(a.id);
      var bi = recent.indexOf(b.id);
      if (ai !== -1 && bi !== -1)
        return ai - bi;
      if (ai !== -1)
        return -1;
      if (bi !== -1)
        return 1;
      return a.name.localeCompare(b.name);
    });
  }

  onFilteredAppsChanged: selectedIndex = 0

  function launchEntry(entry) {
    AppLauncherState.recordLaunch(entry.id);
    entry.execute();
    AppLauncherState.hide();
  }
  
  function navigate(delta) {
    if (filteredApps.length === 0)
      return;
    selectedIndex = (selectedIndex + delta + filteredApps.length) % filteredApps.length;
    listView.positionViewAtIndex(selectedIndex, ListView.Contain)
  }

  Connections {
    target: AppLauncherState 
    function onLauncherVisibleChanged() {
      if (AppLauncherState.launcherVisible) {
        searchInput.text = "";
        root.searchQuery = "";
        root.selectedIndex = 0;
        searchInput.forceActiveFocus();
      }
    }
  }

  // Accent Colors 
  // readonly property color accentFill: Qt.rgba(Colors.colBlue.r, Colors.colBlue.g, Colors.colBlue.b, 0.18)
  readonly property color accentFill: Style.accent // Qt.rgba(1, 1, 1, 0.07) // "#292d33"
  readonly property color accentIcon: "transparent" // Qt.rgba(1, 1, 1, 0.07)
  // readonly property color fgDim: Qt.rgba(Colors.colFg.r, Colors.colFg.g, Colors.colFg.b, 0.65)
  readonly property color fgDim: Style.text

  // Panel Geometry
  readonly property int maxVisible: 7
  readonly property int itemH: 50
  readonly property int panelW: 550

  readonly property int bezel: 0          // thickness of your bottom frame/bezel, set this to match
  readonly property int flare: Style.cornerRadius          // radius of the concave corners
  readonly property int topRadius: Style.cornerRadius      // radius of the top corners
  readonly property color frameColor: Style.shell // "#d910242d"   // match your bezel's color

  readonly property int totalW: panelW + 2 * flare
  readonly property int panelH: contentColumn.implicitHeight + 24 + bezel

  MouseArea {
    anchors.fill: parent 
    enabled: AppLauncherState.launcherVisible 
    onClicked: AppLauncherState.hide()
  }

  Item {
    id: panel
    width: root.totalW
    height: root.panelH
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom

    Behavior on height {
      NumberAnimation {
        duration: 500
        easing.type: Easing.OutCubic
      }
    }

    transform: Translate {
      y: AppLauncherState.launcherVisible ? 0 : root.panelH + 6
        Behavior on y {
          NumberAnimation {
            duration: 280
              easing.type: Easing.OutCubic
          }
        }
      }

      Shape {
        id: frame
        anchors.fill: parent
        layer.enabled: true
        layer.samples: 4

        readonly property real w: width
        readonly property real h: height
        readonly property real f: root.flare
        readonly property real r: root.topRadius
        readonly property real yb: height - root.bezel   // inner edge of the bezel

        // Filled silhouette: panel + concave flares, extending down into the bezel
        ShapePath {
          strokeWidth: -1
          fillColor: root.frameColor
          startX: 0
          startY: frame.h

          PathLine { x: 0; y: frame.yb }
          PathArc {
            x: frame.f; y: frame.yb - frame.f
              radiusX: frame.f; radiusY: frame.f
              direction: PathArc.Counterclockwise
          }
          PathLine { x: frame.f; y: frame.r }
          PathArc {
            x: frame.f + frame.r; y: 0
              radiusX: frame.r; radiusY: frame.r
              direction: PathArc.Clockwise
          }
          PathLine { x: frame.w - frame.f - frame.r; y: 0 }
          PathArc {
            x: frame.w - frame.f; y: frame.r
              radiusX: frame.r; radiusY: frame.r
              direction: PathArc.Clockwise
          }
          PathLine { x: frame.w - frame.f; y: frame.yb - frame.f }
          PathArc {
            x: frame.w; y: frame.yb
              radiusX: frame.f; radiusY: frame.f
              direction: PathArc.Counterclockwise
          }
          PathLine { x: frame.w; y: frame.h }
          PathLine { x: 0; y: frame.h }
        }

        // Subtle outline, visible edge only (no lines across the bezel)
        ShapePath {
          strokeWidth: 1
          strokeColor: Style.shell
          fillColor: "transparent"
          startX: 0
          startY: frame.yb

          PathArc {
            x: frame.f; y: frame.yb - frame.f
            radiusX: frame.f; radiusY: frame.f
            direction: PathArc.Counterclockwise
          }
          PathLine { x: frame.f; y: frame.r }
          PathArc {
            x: frame.f + frame.r; y: 0
            radiusX: frame.r; radiusY: frame.r
            direction: PathArc.Clockwise
          }
          PathLine { x: frame.w - frame.f - frame.r; y: 0 }
          PathArc {
           x: frame.w - frame.f; y: frame.r
             radiusX: frame.r; radiusY: frame.r
             direction: PathArc.Clockwise
          }
          PathLine { x: frame.w - frame.f; y: frame.yb - frame.f }
          PathArc {
            x: frame.w; y: frame.yb
            radiusX: frame.f; radiusY: frame.f
            direction: PathArc.Counterclockwise
          }
        }
      }

      // swallow clicks so they don't hit the dismiss area
      MouseArea {
        anchors.fill: parent
      }

      // Content area, offset past the left flare and kept above the bezel
      Item {
        x: root.flare
        width: root.panelW
        height: parent.height - root.bezel
        clip: true

        Column {
          id: contentColumn
          anchors {
            top: parent.top
            topMargin: 12
            left: parent.left 
            leftMargin: 12
            right: parent.right
            rightMargin: 12
          }

          spacing: 0

          Rectangle {
            width: 36
            height: 4
            radius: 2
            anchors.horizontalCenter: parent.horizontalCenter
            color: "#404054"
          }

          Item {
            width: 1
            height: 8
          }

          Rectangle {
            width: parent.width
            height: 44
            radius: 10
            color: Qt.rgba(1, 1, 1, 0.07)

            Rectangle {
              anchors.fill: parent
              radius: 10
              color: "transparent"
              border.color: "#d910242d"
              border.width: 1
              opacity: searchInput.activeFocus ? 0.55 : 0

              Behavior on opacity {
                NumberAnimation {
                  duration: 150
                }
              }
            }

            Row {
              anchors {
                fill: parent
                leftMargin: 14
                rightMargin: 14
              }
              spacing: 10

              Item {
                width: parent.width - 40
                height: parent.height

                Text {
                  anchors.fill: parent 
                  text: root.isSearching ? "" : "Search for..."
                  color: "white"
                  opacity: 0.28
                  font {
                    pixelSize: 13
                    family: "JetBrainsMono Nerd Font"
                  }
                  verticalAlignment: Text.AlignVCenter
                  visible: searchInput.text === ""
                }

                TextInput {
                  id: searchInput
                  anchors.fill: parent 
                  color: "white"
                  opacity: 0.28
                  selectionColor: root.accentFill
                  font {
                    pixelSize: 13
                    family: "JetBrainsMono Nerd Font"
                  }
                  verticalAlignment: TextInput.AlignVCenter
                  clip: true 
                  onTextChanged: root.searchQuery = text

                  Keys.onPressed: function (event) {
                    if (event.key === Qt.Key_Up) {
                      root.navigate(-1);
                      event.accepted = true;
                    } else if (event.key === Qt.Key_Down) {
                      root.navigate(1);
                      event.accepted = true;
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                      if (root.filteredApps.length > 0)
                        root.launchEntry(root.filteredApps[root.selectedIndex]);
                      event.accepted = true;
                    } else if (event.key === Qt.Key_Escape) {
                      AppLauncherState.hide();
                      event.accepted = true;
                    }
                  }
                }
              }
            }
          }

          Item {
            width: 1
            height: 8
          }

          ListView {
            id: listView 
            width: parent.width
            // height: Math.min(root.filteredApps.length, root.maxVisible) * root.itemH
            height: Math.max(1, Math.min(root.filteredApps.length, root.maxVisible) * root.itemH)
            model: root.filteredApps
            clip: true 
            interactive: false 

            MouseArea {
              anchors.fill: parent 
              onWheel: function (wheel) {
                if (wheel.angleDelta.y < 0)
                  root.navigate(1);
                else 
                  root.navigate(-1);
              }
            }

            Text {
              anchors.centerIn: parent
              visible: root.filteredApps.length === 0
              text: "No apps found :("
              color: "white"
              opacity: 0.28
              font {
                pixelSize: 13
                family: "JetBrainsMono Nerd Font"
              }
            }

            delegate: Item {
              id: appRow
              width: listView.width
              height: root.itemH

              readonly property bool sel: root.selectedIndex === index 
              readonly property bool isRecent: !root.isSearching && AppLauncherState.recentIds.indexOf(modelData.id) !== -1 && AppLauncherState.recentIds.indexOf(modelData.id) < 5

              Rectangle {
                anchors {
                  fill: parent
                  topMargin: 2
                  bottomMargin: 2
                }
                radius: 10
                color: appRow.sel ? Qt.rgba(1, 1, 1, 0.07) : "transparent"
                Behavior on color {
                  ColorAnimation {
                    duration: 100
                  }
                }

                Row {
                  anchors {
                    fill: parent
                    leftMargin: 8
                    rightMargin: 8
                  }
                  spacing: 12

                  Rectangle {
                    width: 36
                    height: 36
                    radius: 9
                    anchors.verticalCenter: parent.verticalCenter
                    color: appRow.sel ? root.accentIcon : Qt.rgba(1, 1, 1, 0.08)
                    Behavior on color {
                      ColorAnimation {
                        duration: 100
                      }
                    }

                    Image {
                      id: appIcon 
                      anchors.centerIn: parent 
                      width: 22
                      height: 22
                      source: modelData.icon !== "" ? "image://icon/" + modelData.icon : ""
                      smooth: true 
                      mipmap: true
                    }

                    Text {
                      anchors.centerIn: parent
                      visible: appIcon.status !== Image.Ready 
                      text: modelData.name.charAt(0).toUpperCase()
                      font {
                        pixelSize: 15
                        family: "JetBrainsMono Nerd Font"
                        weight: Font.Bold 
                      }
                      // color: appRow.sel ? Qt.rgba(1, 1, 1, 0.07) : Qt.rgba(1, 1, 1, 0.07)
                      color: "white"
                      Behavior on color {
                        ColorAnimation {
                          duration: 100
                        }
                      }
                    }
                  }

                  Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Text {
                      text: modelData.name 
                      font {
                        pixelSize: 13
                        family: "JetBrainsMono Nerd Font"
                        weight: appRow.sel ? Font.Medium : Font.Normal
                      }
                      // color: appRow.sel ? Colors.colFg : root.fgDim 
                      color: "white"
                      opacity: 0.28
                      Behavior on color {
                        ColorAnimation {
                          duration: 100
                        }
                      }
                    }

                    Row {
                      spacing: 6
                      visible: appRow.isRecent || modelData.genericName !== ""

                      Rectangle {
                        visible: appRow.isRecent
                        width: recentLabel.width + 8
                        height: 14
                        radius: 4
                        // color: Qt.rgba(Colors.colBlue.r, Colors.colBlue.g, Colors.colBlue.b, 0.08)
                        // color: "#292d33"
                        // color: Qt.rgba(1, 1, 1, 0.07)
                        color: "white"
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                          id: recentLabel
                          anchors.centerIn: parent
                          text: "Recent"
                          font {
                            pixelSize: 9
                            family: "JetBrainsMono Nerd Font"
                          }
                          // color: Colors.colBlue 
                          color: "white"
                        }
                      }

                      Text {
                        visible: modelData.genericName !== ""
                        text: modelData.genericName
                        font {
                          pixelSize: 11
                          family: "JetBrainsMono Nerd Font"
                        }
                        // color: Colors.colFg
                        color: "white"
                        opacity: 0.35
                        anchors.verticalCenter: parent.verticalCenter
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
}
