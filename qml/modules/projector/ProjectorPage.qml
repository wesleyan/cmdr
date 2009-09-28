import Qt 4.6
Item {
    anchors.fill: parent
    anchors.horizontalCenter: parent.horizontalCenter

    Item {
        anchors.fill: parent
        z: true || true? -1 : 1
        opacity: true || true? 0 : 1
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
        source: "images/large/" + projectorcontroller.state + ".png"
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
        text: projectorcontroller.state == "offState" ? "power on" : "power off"
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: projectorImage.bottom
        anchors.topMargin: 20
        onClicked: {
            projectorcontroller.setPower(projectorcontroller.state == "offState");
        }
        opacity: projectorcontroller.state == "offState" || projectorcontroller.state == "onState" || projectorcontroller.state == "muteState" ? 1 : 0
    }
    ButtonComponent {
        id: muteButton
        imageSource: "images/mute_symbol.png"
        imageWidth: 44
        imageHeight: 44
        text: "mute video"
        state: projectorcontroller.state == ("onState" || "muteState") ? "" : "hidden"
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: offButton.bottom
        anchors.topMargin: 20
        onClicked: {
            projectorcontroller.setVideoMute(projectorcontroller.state == "onState");
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
