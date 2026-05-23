import Quickshell
import Quickshell.Wayland
import QtQuick
import qs
// import qs.theme

Variants {
    id: root
    model: Quickshell.screens
    property bool rightBarVisible: true

    delegate: PanelWindow {
        id: rightBarWindow
        visible: rightBarVisible

        // --- Screen Mapping ---
        required property var modelData
        screen: modelData

        // --- Layer Shell Configuration ---
        WlrLayershell.layer: WlrLayer.Top
        // WlrLayershell.exclusionMode: ExclusionMode.Ignore

        // --- Geometry & Positioning ---
        anchors {
            top: true
            right: true
            bottom: true
        }

        // --- Visual Styling ---
        implicitWidth: Layout.sideBarWidth
        color: "transparent"
    }
}
