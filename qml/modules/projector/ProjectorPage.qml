import Qt 4.6
Item {
    anchors.fill: parent
    anchors.horizontalCenter: parent.horizontalCenter
    ProjectorController {
        id: projector
    }
    Rect {
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
                SetProperties {
                    target: muteButton
                    opacity: 0
                }
            }
        ]
    }
}
