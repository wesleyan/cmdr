import Qt 4.6
import WesControl 1.0

Item {
    Image {
        source: "images/Background.png"
        y: -20
        x: 100
        /*transform: [
            Rotation3D { id: rotation; origin.x: 0; axis.x: 30; axis.y: 0; angle: 30 }
        ]*/
        Item {
            id: topContainer
            y: 40
            height: 36
            width: 179
            anchors.horizontalCenter: parent.horizontalCenter
            Image {
                id: dvdButton
                source: "images/DVD_Button.png"
                x: 0
                anchors.verticalCenter: parent.verticalCenter
                opacity: 0
            }
            Image {
                id: vcrButton
                source: "images/VCR_Button.png"
                anchors.left: dvdButton.right
                anchors.leftMargin: 0
                anchors.verticalCenter: parent.verticalCenter
                opacity: 0
            }
            Image {
                id: ejectButton
                source: "images/Eject_button.png"
                anchors.left: vcrButton.right
                anchors.leftMargin: 20
                anchors.verticalCenter: parent.verticalCenter
            }
        }
        Item {
            id: navigationContainer
            width: 179
            height: 151
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: topContainer.bottom
            anchors.topMargin: 20
            Image {
                property string selected
                id: navigationButtons
                source: selected == "" ? "images/navigation/navigation_buttons.png" : "images/navigation/navigation_" + selected + "_selected.png"
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                MaskedMouseRegion
                {
                    anchors.fill: parent
                    maskPath: "qml/modules/remote/images/navigation/navigation_left_mask.png"
                    onPressed: {
                        parent.selected = "left"
                    }
                    onReleased: {
                        if(parent.selected == "left")parent.selected = ""
                    }
                }
                MaskedMouseRegion
                {
                    anchors.fill: parent
                    maskPath: "qml/modules/remote/images/navigation/navigation_down_mask.png"
                    onPressed: {
                        parent.selected = "down"
                    }
                    onReleased: {
                        if(parent.selected == "down")parent.selected = ""
                    }
                }
                MaskedMouseRegion
                {
                    anchors.fill: parent
                    maskPath: "qml/modules/remote/images/navigation/navigation_right_mask.png"
                    onPressed: {
                        parent.selected = "right"
                    }
                    onReleased: {
                        if(parent.selected == "right")parent.selected = ""
                    }
                }
                MaskedMouseRegion
                {
                    anchors.fill: parent
                    maskPath: "qml/modules/remote/images/navigation/navigation_up_mask.png"
                    onPressed: {
                        parent.selected = "up"
                    }
                    onReleased: {
                        if(parent.selected == "up")parent.selected = ""
                    }
                }
                MaskedMouseRegion
                {
                    anchors.fill: parent
                    maskPath: "qml/modules/remote/images/navigation/navigation_center_mask.png"
                    onPressed: {
                        parent.selected = "center"
                    }
                    onReleased: {
                        if(parent.selected == "center")parent.selected = ""
                    }
                }
            }
        }
        Image {
            id: playButton
            source: "images/Play_button.png"
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: navigationContainer.bottom
            anchors.topMargin: 20
            MouseRegion {
                anchors.fill: parent
                onPressed: {
                    parent.opacity = 0.6
                    iremitter.send_command("play");
                }
                onReleased: {
                    parent.opacity = 1
                }
            }
        }
        Item {
            id: rewPauseFFContainer
            anchors.horizontalCenter: parent.horizontalCenter
            width: 175
            height: 71
            anchors.top: playButton.bottom
            anchors.topMargin: 2
            Image {
                id: rewindButton
                source: "images/Rewind_button.png"
                anchors.left: parent.left
                MaskedMouseRegion
                {
                    anchors.fill: parent
                    maskPath: "qml/modules/remote/images/Rewind_button.png"
                    onPressed: {
                        parent.opacity = 0.6
                    }
                    onReleased: {
                        parent.opacity = 1
                    }
                }
            }
            Image {
                id: pauseButton
                source: "images/Pause_button.png"
                anchors.horizontalCenter: parent.horizontalCenter
                MaskedMouseRegion
                {
                    anchors.fill: parent
                    maskPath: "qml/modules/remote/images/Pause_button.png"
                    onPressed: {
                        parent.opacity = 0.6;
                        iremitter.send_command("pause");
                    }
                    onReleased: {
                        parent.opacity = 1
                    }
                }
            }
            Image {
                id: ffButton
                source: "images/FF_button.png"
                anchors.right: parent.right
                MaskedMouseRegion
                {
                    anchors.fill: parent
                    maskPath: "qml/modules/remote/images/FF_button.png"
                    onPressed: {
                        parent.opacity = 0.6
                    }
                    onReleased: {
                        parent.opacity = 1
                    }
                }
            }
        }
        Image {
            id: stopButton
            source: "images/Stop_button.png"
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: rewPauseFFContainer.bottom
            anchors.topMargin: 2
            MouseRegion {
                anchors.fill: parent
                onPressed: {
                    parent.opacity = 0.6
                }
                onReleased: {
                    parent.opacity = 1
                }
            }
        }
        Item {
            id: prevNextButtons
            width: 175
            height: 48
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: stopButton.bottom
            anchors.topMargin: 2
            Image {
                id: prevButton
                source: "images/Prev_button.png"
                anchors.left: parent.left
                MouseRegion {
                    anchors.fill: parent
                    onPressed: {
                        parent.opacity = 0.6
                    }
                    onReleased: {
                        parent.opacity = 1
                    }
                }
            }
            Image {
                id: nextButton
                source: "images/Next_button.png"
                anchors.right: parent.right
                MouseRegion {
                    anchors.fill: parent
                    onPressed: {
                        parent.opacity = 0.6
                    }
                    onReleased: {
                        parent.opacity = 1
                    }
                }
            }
        }
        Item {
            id: menuTitleButtons
            width: 175
            height: 48
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: prevNextButtons.bottom
            anchors.topMargin: 2
            Image {
                id: menuButton
                source: "images/Menu_button.png"
                anchors.left: parent.left
                MouseRegion {
                    anchors.fill: parent
                    onPressed: {
                        parent.opacity = 0.6
                    }
                    onReleased: {
                        parent.opacity = 1
                    }
                }
            }
            Image {
                id: titleButton
                source: "images/Title_button.png"
                anchors.right: parent.right
                MouseRegion {
                    anchors.fill: parent
                    onPressed: {
                        parent.opacity = 0.6
                    }
                    onReleased: {
                        parent.opacity = 1
                    }
                }
            }
        }
    }
}
