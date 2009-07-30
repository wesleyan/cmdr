import Qt 4.6
Item {
    property string currentSource
    resources: [
        ListModel {
            id: SourcesModel
            ListElement {
                name: "Mac"
                imageSource: "mac.png"
                imageWidth: 115
                imageHeight: 54
                projectorInput: "RGB1"
                switcherInput: 1
            }
            ListElement {
                name: "PC"
                imageSource: "computer.svg"
                imageWidth: 95
                imageHeight: 95
                projectorInput: "RGB1"
                switcherInput: 2
            }
            ListElement {
                name: "Laptop"
                imageSource: "laptop.svg"
                imageWidth: 80
                imageHeight: 73
                projectorInput: "RGB1"
                switcherInput: 3
            }
            ListElement {
                name: "DVD"
                imageSource: "DVD.png"
                imageWidth: 70
                imageHeight: 70
                projectorInput: "RGB1"
                switcherInput: 4
            }
        }
    ]

    Projector {
        id: projector
    }

    VideoSwitcher {
        id: switcher
    }
}
