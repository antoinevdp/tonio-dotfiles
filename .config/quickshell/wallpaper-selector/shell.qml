//@ pragma UseQApplication
import QtQuick
import Quickshell
import Quickshell.Wayland
import "wallpaper"

ShellRoot {
    Component.onCompleted: {
        Qt.application.organizationName = "opencode";
        Qt.application.organizationDomain = "local";
        Qt.application.applicationName = "wallpaper-selector";
    }

    PanelWindow {
        id: root

        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        focusable: true
        visible: true

        WlrLayershell.namespace: "wallpaper-selector"
        WlrLayershell.layer: WlrLayer.Overlay

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        MouseArea {
            anchors.fill: parent
            onClicked: Qt.quit()
        }

        WallpaperPicker {
            id: picker
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            height: Math.min(parent.height, 650)
            visible: true
        }
    }
}
