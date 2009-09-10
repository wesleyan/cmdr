import Qt 4.6
import WesControl
Rect {
    resources: [
        XmlListModel {
            id: SourcesModel
            source: "../../../pages.xml"
            query: "/WesControl/page[name=\"Source\"]/configuration/sources/source"
            XmlRole {
                name: "name"
                query: "name/string()"
            }
            XmlRole {
                name: "imageSource"
                query: "image/@source/string()"
            }
            XmlRole {
                name: "imageWidth"
                query: "image/@width/number()"
            }
            XmlRole {
                name: "imageHeight"
                query: "image/@height/number()"
            }
        }
    ]
    height: parent.height
    width: parent.width
    radius: 20
    color:"#F2F2F2"
    opacity: 0.9
    clip: true

    Component {
        id: ListDelegate
        Item {
            height: 90
            width: parent.width
            Rect {
                id: backgroundRect
                anchors.fill: parent
                opacity: 0
                gradient: Gradient {
                    GradientStop {
                        position: 0
                        color: "#6E6E6E"
                    }
                    GradientStop {
                        position: 1
                        color: "#292929"
                    }
                }
            }
            Item {
                id: imageBox
                width: 150
                height: parent.height
                Image {
                    source: "images/" + imageSource
                    width: imageWidth
                    height: imageHeight
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                    smooth: true
                }
            }
            Item {
                height: parent.height
                anchors.left: imageBox.right
                Text {
                    id: nameText
                    anchors.verticalCenter: parent.verticalCenter
                    font.family: "Myriad Pro"
                    font.size: 54
                    text: name
                    color: "black"
                }
            }
            Rect {
                height: 1
                width: parent.width
                color: "#CCCCCC"
                anchors.top: parent.bottom
            }
            MouseRegion {
                id: sourceMouseRegion
                anchors.fill: parent
                onPressed: {
                    if(sourcesView.currentIndex != index)sourcecontroller.source = name
                    sourcesView.currentIndex = index
                }
            }
            Connection {
                sender: sourcecontroller
                signal: "sourceChanged()"
                script: {
                    if(sourcecontroller.source == name)sourcesView.currentIndex = index
                }
            }
            states: [
                State {
                    name: "selected"
                    when: sourcesView.currentIndex == index
                    SetProperties {
                        target: backgroundRect
                        opacity: 1
                    }
                    SetProperties {
                        target: nameText
                        color: "white"
                    }

                    /*SetProperties {
                        target: projector
                        input: projectorInput
                    }
                    SetProperties {
                        target: videoswitcher
                        input: switcherInput
                    }*/
                }
            ]
            transitions: [
                Transition {
                    fromState: ""
                    toState: "selected"
                    NumberAnimation {
                    }
                }
            ]
        }
    }

    ListView {
        id: sourcesView
        height: parent.height
        width: parent.width
        delegate: ListDelegate
        model: SourcesModel
        clip: true
        //locked: true
        //currentItemPositioning: "SnapAuto"
    }
}
