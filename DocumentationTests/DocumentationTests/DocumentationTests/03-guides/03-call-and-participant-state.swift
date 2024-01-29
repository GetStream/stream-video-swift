import StreamVideo
import StreamVideoSwiftUI

@MainActor
fileprivate func content() {
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
        let cancellable = call.state.$participants.sink { participants in
            // ..
        }

        // you
        let localParticipant: CallParticipant? = call.state.localParticipant
    }

    container {
        let state = streamVideo.state
    }
}
