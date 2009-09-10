import Qt 4.6
Item {
    height: 80
    width: 90
    Image {
        id: volumeButton
        width: 70
        height: 33.9
        source: "images/speaker.png"
        smooth: true
        anchors.horizontalCenter: parent.horizontalCenter
        y: 10
    }
}
