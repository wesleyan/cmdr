import Qt 4.6
import WesControl 1.0
Item {
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
        },
        Component {
            id: ImageComponent
            Connection {
                sender: sourcecontroller
                signal: "sourceChanged()"
                script: {
                    print("Source changed");
                    if(sourcecontroller.source == name)
                    {
                        sourcesButton.source = imageSource
                    }
                }
            }
        }
    ]
    height: 80
    width: 90
    Image {
        id: sourcesButton
        width: 70
        height: 33.9
        smooth: true
        anchors.horizontalCenter: parent.horizontalCenter
        y: 10
    }
    Repeater {
        delegate: ImageComponent
        model: SourcesModel
    }
}
