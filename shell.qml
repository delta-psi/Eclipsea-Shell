import Quickshell
import Quickshell.Io
import QtQuick
import qs
import qs.App_Launcher
// import "./App_Launcher/"

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

  AppLauncher {
    id: appLauncher
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
    target: "desktopBezels"

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
      Style.cornerRadius = Style.cornerRadius > 0 ? 0 : 30
    }
  }
}
