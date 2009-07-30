import Qt 4.6
Item {
    height: 80
    width: 90
    ProjectorController {
        id: projector
    }
    Image {
        id: projectorButton
        height: 67
        source: "images/button/" + projector.realState + ".png"
        smooth: true
        anchors.centeredIn: parent
    }
}
