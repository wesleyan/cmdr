import Qt 4.6
Item {
    anchors.fill: parent
    anchors.horizontalCenter: parent.horizontalCenter
    ProjectorController {
        id: projector
    }
    Item {
        anchors.fill: parent
        z: projector.connected? -1 : 1
        opacity: projector.connected? 0 : 1
        Rectangle {
            color: "black"
            radius: 20
            opacity: 0.95
            anchors.fill: parent
            anchors.horizontalCenter: parent.horizontalCenter
            MouseRegion {
                anchors.fill: parent
            }
        }
        Text {
            id: unableToConnectText
            text: "Unable to connect to projector"
            font.family: "Myriad Pro"
            font.pointSize: 40
            color: "white"
            wrap: true
            width: parent.width-30
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 100
            horizontalAlignment: "AlignHCenter"
        }
        Text {
            text: "Please call #4959 for assistance"
            font.family: "Myriad Pro"
            font.pointSize: 20
            color: "white"
            width: parent.width-30
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: unableToConnectText.bottom
            anchors.topMargin: 50
            horizontalAlignment: "AlignHCenter"
        }
    }
    Rectangle {
        color:"black"
        radius: 20
        opacity: 0.8
        anchors.fill: parent
        anchors.horizontalCenter: parent.horizontalCenter
    }
    Image {
        id: projectorImage
        source: "images/large/" + projector.realState + ".png"
        height: 230
        width: 195
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 20
    }
    ButtonComponent {
        id: offButton
        imageSource: "images/off_symbol.png"
        imageWidth: 36.36
        imageHeight: 43.154
        text: projector.realState == "offState" ? "power on" : "power off"
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: projectorImage.bottom
        anchors.topMargin: 20
        onClicked: {
            if(projector.realState == "offState")projector.state = "onState";
            if(projector.realState == "onState")projector.state = "offState";
        }
    }
    ButtonComponent {
        id: muteButton
        imageSource: "images/mute_symbol.png"
        imageWidth: 44
        imageHeight: 44
        text: "mute video"
        state: projector.realState == ("onState" || "muteState") ? "" : "hidden"
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: offButton.bottom
        anchors.topMargin: 20
        onClicked: {
            if(projector.realState == "muteState")projector.state = "onState";
            else if(projector.realState == "onState") projector.state = "muteState";
        }
        states: [
            State {
                name: "hidden"
                PropertyChanges {
                    target: muteButton
                    opacity: 0
                }
            }
        ]
    }
}
