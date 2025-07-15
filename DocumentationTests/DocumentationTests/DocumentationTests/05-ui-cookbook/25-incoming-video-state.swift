import StreamVideo
import StreamVideoSwiftUI
import SwiftUI
import Combine

@MainActor
fileprivate func content() {
    asyncContainer {
        let call = streamVideo.call(callType: "default", callId: "my-call-id")
        await call.updateClientCapabilities([.subscriberVideoPause])
    }

    container {
        let cancellable = call
            .state
            .$participants
            .sink { participants in
                let pausedVideoParticipants = participants.filter {
                    $0.pausedTracks.contains(.video)
                }

                print("Participants with paused video tracks: \(pausedVideoParticipants)")
            }

        // Cancel when no longer needed:
        cancellable.cancel()
    }
}
