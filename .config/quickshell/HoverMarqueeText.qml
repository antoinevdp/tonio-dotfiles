import QtQuick

Item {
    id: root

    property string text: ""
    property color textColor: "white"
    property string fontFamily: "SpaceMono Nerd Font"
    property int pixelSize: 14
    property bool hovered: false

    implicitHeight: textItem.implicitHeight
    clip: true

    Text {
        id: textItem
        text: root.text
        color: root.textColor
        font.family: root.fontFamily
        font.pixelSize: root.pixelSize
        anchors.verticalCenter: parent.verticalCenter
        x: 0
        width: root.hovered ? implicitWidth : root.width
        elide: root.hovered ? Text.ElideNone : Text.ElideRight
    }

    SequentialAnimation {
        id: marqueeAnim
        running: root.hovered && textItem.implicitWidth > root.width
        loops: Animation.Infinite

        onRunningChanged: {
            if (!running)
                textItem.x = 0;
        }

        PauseAnimation { duration: 250 }
        NumberAnimation {
            target: textItem
            property: "x"
            from: 0
            to: -(textItem.implicitWidth - root.width)
            duration: Math.max(1200, (textItem.implicitWidth - root.width) * 30)
            easing.type: Easing.Linear
        }
        PauseAnimation { duration: 500 }
        NumberAnimation {
            target: textItem
            property: "x"
            to: 0
            duration: 250
            easing.type: Easing.OutCubic
        }
    }
}
