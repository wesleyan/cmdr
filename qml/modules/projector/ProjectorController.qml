Item {
    property string realState

    Projector {
        id: projector
    }

    realState: projector.warming ? "warmingState" :
        (projector.cooling ? "coolingState" :
        (!projector.power ? "offState" :
        (projector.videoMute ? "muteState" : "onState")))

    states: [
        State {
            name: "onState"
            SetProperties {
                target: projector
                power: true
                video_mute: false
            }
        },
        State {
            name: "offState"
            SetProperties {
                target: projector
                power: false
            }
        },
        State {
            name: "muteState"
            SetProperties {
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
