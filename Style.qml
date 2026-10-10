pragma Singleton
import QtQuick
import qs.Theme

QtObject {
    property int topBarHeight: 7
    property int sideBarWidth: 7
    property int bottomBarHeight: 7
    property int cornerRadius: 30
    property int mainBarWidth: 45

    // Opacity
    property real alpha: 0.85

    // Typed base colors (string -> color conversion happens here)
    readonly property color surface: Colors.md3.surface_container
    readonly property color surfaceRaised: Colors.md3.surface_container_high
    readonly property color text: Colors.md3.on_surface
    readonly property color accent: Colors.md3.primary

    // What every shell surface (bezels, bars, launcher) should fill with
    readonly property color shell: Qt.alpha(surface, alpha)
    readonly property color shellRaised: Qt.alpha(surfaceRaised, alpha)
    readonly property color shellBorder: Qt.alpha(text, 0.10)
}
