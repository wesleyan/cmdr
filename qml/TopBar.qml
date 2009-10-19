import Qt 4.6
Item {
    id: topBar

    Script { source: "date.format.js" }

    Timer {
         interval: 500; running: true; repeat: true
         onTriggered: timeText.text = (new Date()).format("h:MM TT")
     }

    Text {
        id: timeText
        width: parent.width
        text: (new Date()).format("h:MM TT")
        color: "white"
        font.pointSize: 18
        font.family: "Myriad Pro"
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.leftMargin: 10
        anchors.bottomMargin: 5
    }

    Text {
        text: "Exley 121"
        font.pointSize: 22
        color: "white"
        font.family: "Myriad Pro"
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 5

    }

    Rectangle {
        radius: 10
        width: 112
        height: 28
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 6
        color: "#7C7C7C"
        opacity: 0
        Text {
            text: "Log In"
            color: "white"
            font.family: "Myriad Pro"
            font.pointSize: 12
            anchors.centerIn: parent
        }
    }
}
