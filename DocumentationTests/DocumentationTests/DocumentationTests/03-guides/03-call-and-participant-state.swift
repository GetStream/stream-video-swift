//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import StreamVideo
import StreamVideoSwiftUI

@MainActor
private func content() {
    container {
        let clientState = streamVideo.state
        let callState = call.state
        let participants = call.state.participants
    }

    asyncContainer {
        let call = streamVideo.call(callType: "default", callId: "mycall")
        let joinResult = try await call.join(create: true)
        // state is now available at
        let state = call.state
    }

    container {
        let cancellable = call.state.$participants.sink { _ in
            // ..
        }

        // you
        let localParticipant: CallParticipant? = call.state.localParticipant
    }

    container {
        let state = streamVideo.state
    }

    container {
        @MainActor
        class CallObserver {
            private var cancellables = Set<AnyCancellable>()

            func observeCallState(call: Call) {
                // Observe participants
                call.state.$participants
                    .sink { participants in
                        print("Participants updated: \(participants.count)")
                    }
                    .store(in: &cancellables)

                // Observe recording state
                call.state.$recordingState
                    .sink { state in
                        print("Recording state: \(state)")
                    }
                    .store(in: &cancellables)

                // Observe connection quality
                call.state.$reconnectionStatus
                    .sink { status in
                        if status == .disconnected {
                            print("Connection lost")
                        }
                    }
                    .store(in: &cancellables)
            }
        }
    }
}
