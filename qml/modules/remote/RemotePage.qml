Item {
    Image {
        source: "images/Background.png"
        y: -20
        x: 100
        Image {
            id: dvdButton
            source: "images/DVD_Button.png"
            x: 40
            y: 40
        }
        Image {
            id: vcrButton
            source: "images/VCR_Button.png"
            x: 110
            y: 40
        }
        Image {
            id: ejectButton
            source: "images/Eject_button.png"
            x: 190
            y: 39
        }
        Image {
            id: navigationButtons
            source: "images/DirectionalButtons.png"
            anchors.horizontalCenter: parent.horizontalCenter
            y: 110
        }
        Image {
            id: playButton
            source: "images/Play_button.png"
            anchors.horizontalCenter: parent.horizontalCenter
            y: 300
        }
        Item {
            y: 43+10+300
            anchors.horizontalCenter: parent.horizontalCenter
            width: 179
            Image {
                id: rewindButton
                source: "images/Rewind_button.png"
                x: 0
                PolygonalMouseRegion
                {
                    anchors.fill: parent
                    imagePath: "qml/modules/remote/images/Rewind_button.png"
                    onPressedInside: {
                        parent.opacity = 0.3
                    }
                    onReleased: {
                        parent.opacity = 1
                    }
                }
            }
            Image {
                id: pauseButton
                source: "images/Pause_button.png"
                x: 45.3+10
            }
            Image {
                id: ffButton
                source: "images/FF_button.png"
                x: 45.3 + 10 + 49.3 + 10
            }

        }
        /*PolygonalMouseRegion
        {
            anchors.fill: parent
            points: [1,2,3,4, 6]
        }*/
    }
}
