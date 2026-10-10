import Quickshell
import Quickshell.Wayland
import QtQuick
import qs
// import qs.theme

Variants {
    id: root
    model: Quickshell.screens
    property bool topBarVisible: true

    delegate: PanelWindow {
        id: topBarWindow
        visible: topBarVisible

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
            left: true
        }

        // --- Visual Styling ---
        implicitHeight: Style.topBarHeight
        color: "transparent"
    }
}
