import Qt 4.6
Item {
    height: 80
    width: 90

    Image {
        id: projectorButton
        height: 67
        source: "images/button/" + projectorcontroller.state + ".png"
        smooth: true
        anchors.centerIn: parent
    }
}
