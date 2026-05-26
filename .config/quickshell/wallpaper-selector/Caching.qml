import QtQuick
import Quickshell

QtObject {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string xdgRuntimeDir: Quickshell.env("XDG_RUNTIME_DIR")
    readonly property string cacheDir: home + "/.cache/quickshell"
    readonly property string stateDir: home + "/.local/state/quickshell"
    readonly property string runDir: (xdgRuntimeDir !== "" ? xdgRuntimeDir : "/tmp") + "/quickshell"
    readonly property string logDir: runDir + "/logs"

    function getCacheDir(widgetName) {
        const finalPath = cacheDir + "/" + widgetName;
        Quickshell.execDetached(["mkdir", "-p", finalPath]);
        return finalPath;
    }

    function getStateDir(widgetName) {
        const finalPath = stateDir + "/" + widgetName;
        Quickshell.execDetached(["mkdir", "-p", finalPath]);
        return finalPath;
    }

    function getRunDir(widgetName) {
        const finalPath = runDir + "/" + widgetName;
        Quickshell.execDetached(["mkdir", "-p", finalPath]);
        return finalPath;
    }

    function getLogDir(widgetName) {
        const finalPath = logDir + "/" + widgetName;
        Quickshell.execDetached(["mkdir", "-p", finalPath]);
        return finalPath;
    }
}
