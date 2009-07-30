import Qt 4.6
Item {
    property var pages
    property alias currentIndex: buttonsView.currentIndex //progress :indicatorRect.x
    XmlListModel {
        id: PagesModel
        source: "../pages.xml"
        query: "/WesControl/page"
        XmlRole {
            name: "name"
            query: "name/string()"
        }
        XmlRole {
            name: "buttonItemURL"
            query: "buttonItemURL/string()"
        }
    }


    Component
    {
        id: ButtonComponent
        property int index
        Item {
            id: button
            width: 90
            height: 80
            anchors.verticalCenter: parent.verticalCenter
            Item {
                anchors.fill: parent
                opacity: 0.9

                Item {
                    id: buttonImage
                    qml: buttonItemURL
                }

            }
            Text {
                id: nameText
                color: "white"
                text: name
                font.family: "Myriad Pro"
                font.size: 12
                y: 56
                anchors.horizontalCenter: parent.horizontalCenter
            }
            MouseRegion {
                anchors.fill: parent
                onPressed: {
                    buttonsView.currentIndex = index
                }
            }
            states: [
                State {
                    name: "not_selected"
                    when: index != buttonsView.currentIndex
                    SetProperties {
                        target: nameText
                        color: "gray"
                    }
                    SetProperties {
                        target: button
                        opacity: 0.5
                    }
                }
            ]
            transitions: [
                Transition {
                    ColorAnimation {
                        target: nameText
                    }
                    NumberAnimation {
                        target: button
                        properties: "opacity"
                    }
                }
            ]
        }
    }
    Rect {
        width: parent.width
        height: parent.height
        color: "black"
        anchors.bottom: parent.bottom

        Rect {
            width: parent.width
            height: parent.height/2
            anchors.top: parent.top
            color: "#2A2A2A"
        }
        Component
        {
            id: HighlightComponent
            Item {
                height: parent.height
                width: 90
                Rect {
                    width: 90
                    height: 80
                    color: "#828282"
                    radius: 10
                    opacity: 0.6
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        ListView {
            id: buttonsView
            model: PagesModel
            delegate: ButtonComponent
            width: parent.width
            height: parent.height
            orientation: "Horizontal"
            highlight: HighlightComponent
            focus: true
            autoHighlight: true
            locked: true
            x: 20
        }

        /*MouseRegion {
            id: dragRegion
            anchors.fill: parent
            drag.target: indicatorRect
            drag.axis: "x"
            drag.xmin: 0
            drag.xmax: (90 + 20) * (pages.count - 1) + 20

            onPressed: {
                mouseClickPosition = mouse.x

                //indicatorRect.x = (mouse.x <= dragRegion.drag.xmax) ?  mouse.x - indicatorRect.width/2 : dragRegion.drag.mouse.x - indicatorRect.width/2
            }
            onReleased: {
                mouseClickPosition = mouse.x
                /*size = 20 + 90
                if(mouse.x < 100)indicatorRect.x = 10
                else
                {
                    for(i = 100; i <= drag.xmax; i += size-10)
                    {
                        if(mouse.x > i && mouse.x <= i + size)
                        {
                            indicatorRect.x = i + size/2 - 90/2;
                            print("Setting " + mouse.x + " to " + indicatorRect.x);
                        }
                    }
                }* /
            }
        }*/
    }
}
