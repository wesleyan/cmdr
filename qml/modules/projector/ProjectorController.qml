import Qt 4.6
import WesControl 1.0
Item {
    property string realState
    property alias connected: projector.connected

    Projector {
        id: projector
        onSendMessage: messages.addMessage(message, timeout);
    }


    realState: projector.warming ? "warmingState" :
        (projector.cooling ? "coolingState" :
        (!projector.power ? "offState" :
        (projector.videoMute ? "muteState" : "onState")))

    states: [
        State {
            name: "onState"
            PropertyChanges {
                target: projector
                power: true
                video_mute: false
            }
        },
        State {
            name: "offState"
            PropertyChanges {
                target: projector
                power: false
            }
        },
        State {
            name: "muteState"
            PropertyChanges {
                target: projector
                video_mute: true
            }
        },
        State {
            name: "coolingState"
        },
        State {
            name: "warmingState"
        }
    ]
}
