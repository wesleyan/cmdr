Item {
    id: topBar
    property var time
    property var hours
    property var minutes
    property var meridian
    onTimeChanged: {
        var date = new Date;
        hours = date.getHours();
        minutes = minutes < 10 ? "0" + date.getMinutes() : date.getMinutes();
        meridian = hours < 12 ? "AM" : "PM"
        hours = hours == 0 ? 12 : hours % 12
        timeText.opacity = 1

    }
    Timer {
        interval: 1000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: topBar.time = new Date()
    }

    Text {
        id: timeText
        width: parent.width
        text: hours + ":" + minutes + " " + meridian
        color: "white"
        font.size: 18
        font.family: "Myriad Pro"
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.leftMargin: 10
        anchors.bottomMargin: 5
        opacity: 0
        opacity: Behavior {
            NumberAnimation {
                properties: "opacity"
                duration: 200
            }
        }

    }

    Text {
        text: "Exley 121"
        font.size: 22
        color: "white"
        font.family: "Myriad Pro"
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 5

    }

    Rect {
        radius: 10
        width: 112
        height: 28
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 6
        color: "#7C7C7C"
        Text {
            text: "Log In"
            color: "white"
            font.family: "Myriad Pro"
            font.size: 12
            anchors.centeredIn: parent
        }
    }
}
