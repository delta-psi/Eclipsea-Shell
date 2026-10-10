pragma Singleton
import QtQuick
import QtCore 
import Quickshell 
import Quickshell.Io

Singleton {
  id: root 

  property bool launcherVisible: false 
  property var recentIds: [] 

  property var _settings: Settings {
    category: "App Launcher"
    property string recentIdsSerialized: "[]"
  }

  FileView {
    id: store 
    path: Quickshell.statePath("app-launcher.json")
    atomicWrites: true

    onLoaded: {
      try {
        root.recentIds = JSON.parse(store.text()) || [];
      } catch (e) {
        root.recentIds = [];
      }
    }
  }

  // Component.onCompleted: {
  //   try {
  //     recentIds = JSON.parse(_settings.recentIdsSerialized)
  //   } catch (e) {
  //     recentIds = []
  //   }
  // }

  function toggle() {
    launcherVisible = !launcherVisible
  }

  function show() {
    launcherVisible = true
  }

  function hide() {
    launcherVisible = false
  }

  function recordLaunch(id) {
    var list = recentIds.slice()
    var idx = list.indexOf(id)

    if (idx !== -1) { list.splice(idx, 1); }
    list.unshift(id)
    
    if (list.length > 12) list = list.slice(0, 12)

    recentIds = list 
    // _settings.recentIdsSerialized = JSON.stringify(list)
    store.setText(JSON.stringify(list))
  }

  function clearRecents() {
    recentIds = []
    // _settings.recentIdsSerialized = "[]"
    store.setText("[]")
  }

}
