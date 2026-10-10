import Quickshell
import Quickshell.Wayland
import QtQuick
import qs
// import qs.theme

/**
 * A transparent shell container positioned at the bottom of every connected screen.
 */
Variants {
    id: root
    model: Quickshell.screens
    property bool bottomBarVisible: true

    delegate: PanelWindow {
        id: bottomBarWindow
        visible: bottomBarVisible

        // --- Screen Mapping ---
        required property var modelData
        screen: modelData

        // --- Layer Shell Configuration ---
        WlrLayershell.layer: WlrLayer.Top
        // WlrLayershell.exclusionMode: ExclusionMode.Ignore

        // --- Geometry & Positioning ---
        anchors {
            left: true
            right: true
            bottom: true
        }

        // --- Visual Styling ---
        implicitHeight: Style.bottomBarHeight
        color: "transparent"
    }
}
