//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamVideo
import StreamVideoSwiftUI

@MainActor
private func content() {
    container {
        let call = streamVideo.call(callType: "default", callId: "123")
        let camera = call.camera
        let microphone = call.microphone
        let speaker = call.speaker
    }

    asyncContainer {
        try await call.camera.enable() // enable the camera
        try await call.camera.disable() // disable the camera
        try await call.camera.flip() // switch between front and back camera
    }

    container {
        call.camera.direction // front/back
        call.camera.status // enabled/ disabled.
    }

    asyncContainer {
        try await call.microphone.enable() // enable the microphone
        try await call.microphone.disable() // disable the microphone
    }
}
