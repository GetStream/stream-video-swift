import StreamVideo
import StreamVideoSwiftUI
import SwiftUI
import Combine

@MainActor
fileprivate func content() {
    asyncContainer {
        let call = streamVideo.call(callType: "default", callId: callId)
        let callResponse = try await call.create(members: members, ring: true)
    }

    asyncContainer {
        let call = streamVideo.call(callType: "default", callId: callId)
        let callResponse = try await call.get(ring: true)
    }

    asyncContainer {
        let call = streamVideo.call(callType: "default", callId: callId)
        let callResponse = try await call.ring()
    }

    asyncContainer {
        let call = streamVideo.call(callType: "default", callId: callId)
        let callResponse = try await call.create(members: members, notify: true)
    }

    asyncContainer {
        let call = streamVideo.call(callType: "default", callId: callId)
        let callResponse = try await call.get(notify: true)
    }

    asyncContainer {
        let call = streamVideo.call(callType: "default", callId: callId)
        let callResponse = try await call.notify()
    }
}
