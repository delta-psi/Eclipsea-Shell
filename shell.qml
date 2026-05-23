import Quickshell
import Quickshell.Io
import QtQuick
import qs

ShellRoot {
  id: root 

  TopBar {
    id: topBar
  }
  BottomBar {
    id: bottomBar
  }
  RightBar {
    id: rightBar
  }

  BezelsMask {
    id: desktopBezels
    bezelVisible: true
  }

  Bar { 
    id: bar 
    barVisible: true
  }

  // Newbar { 
  //   id: bar 
  //   barVisible: true
  // }

  IpcHandler {
    id:barToggleHandler
    target: "bar"

    function barToggle(): void {
      bar.barVisible = !bar.barVisible
    }
  }

  IpcHandler {
    id: bezelsToggleHandler
    target: desktopBezels

    function bezelsToggle(): void {
      desktopBezels.bezelVisible = !desktopBezels.bezelVisible
    }
  }

  IpcHandler {
    target: "togglePanels"
    
    function barBezelToggle(): void {
      bezelsToggleHandler.bezelsToggle()
      barToggleHandler.barToggle()
      topBar.topBarVisible = !topBar.topBarVisible 
      rightBar.rightBarVisible = !rightBar.rightBarVisible 
      bottomBar.bottomBarVisible = !bottomBar.bottomBarVisible
    }
  }

  IpcHandler {
    target: "layout"

    function toggleSquareMode(): void {
      Layout.cornerRadius = Layout.cornerRadius > 0 ? 0 : 30
    }
  }
}
