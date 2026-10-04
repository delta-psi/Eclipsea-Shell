pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects
// import "../theme"

/**
 * Creates aesthetic rounded bezels across all connected monitors.
 * Uses an XOR region mask and an inverted MultiEffect mask to
 * render a solid surface with a transparent "cutout" for the workspace.
 */
Variants {
    id: root
    model: Quickshell.screens
    property bool bezelVisible: true

    delegate: PanelWindow {
        id: bezelWindow

        // --- Model Integration ---
        required property var modelData
        screen: modelData

        // --- Window Configuration ---
        color: "transparent"
        // visible: contentItem.opacity > 0 
        // visible: root.bezelVisible 
        visible: bar.barVisible
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "quickshell-bezels"
        WlrLayershell.exclusiveZone: -1 // Passthrough; do not reserve space

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        mask: Region {
            item: effectContainer
            intersection: Intersection.Xor
        }

        // property real scaleValue: root.bezelVisible ? 1.0 : 0.90
        //
        // Behavior on scaleValue {
        //   NumberAnimation {
        //     duration: 300 
        //       easing.type: Easing.InOutQuad
        //   }
        // }
        //
        // Item {
        //   id: contentItem
        //   anchors.fill: parent
          // opacity: root.bezelVisible ? 1.0 : 0.0
          // Behavior on opacity {
          //   NumberAnimation {
          //     duration: 300
          //     easing.type: Easing.InOutQuad
          //   }
          // }

        //   transform: Scale {
        //     origin.x: bezelWindow.width / 2 
        //     origin.y: bezelWindow.height / 2 
        //     xScale: bezelWindow.scaleValue 
        //     yScale: bezelWindow.scaleValue
        //   }
        // }

        // --- Input & Visual Masking ---
        // XOR intersection ensures clicks pass through the center cutout


        Item {
            id: effectContainer
            anchors.fill: parent

            Item {
                id: bezelLayer
                anchors.fill: parent
                layer.enabled: true

                // Primary Drop Shadow for the bezel edges
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: "#B0000000"
                    shadowVerticalOffset: 0
                    shadowHorizontalOffset: 0
                    blurMax: 20
                    shadowBlur: 0.5
                }

                Rectangle {
                    id: bezelBackground
                    anchors.fill: parent
                    // color: Theme.surface
                    // color: "#1a1b26"
                    // color: Qt.rgba(0.1, 0.1, 0.12, 0.7)
                    color: "#d910242d"
                    layer.enabled: true

                    // Subtracts the cutoutShape from the solid surface
                    layer.effect: MultiEffect {
                        maskSource: cutoutShape
                        maskEnabled: true
                        maskInverted: true
                        maskThresholdMin: 0.5
                        maskSpreadAtMin: 1
                    }
                }

                /**
                 * Cutout Definition
                 * Defines the area where the desktop remains visible.
                 */
                Item {
                    id: cutoutShape
                    anchors.fill: parent
                    layer.enabled: true
                    visible: false // Source item only

                    Rectangle {
                        id: clippingRect
                        anchors.fill: parent

                        // Margins
                        anchors {
                            leftMargin: Layout.mainBarWidth + 1
                            rightMargin: Layout.sideBarWidth
                            topMargin: Layout.topBarHeight
                            bottomMargin: Layout.bottomBarHeight
                        }

                        radius: Layout.cornerRadius
                    }
                }
            }
        }
    }
}
