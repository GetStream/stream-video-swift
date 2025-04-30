//
//  05-proximity-policies.swift
//  DocumentationTests
//
//  Created by Ilias Pavlidakis on 30/4/25.
//

import StreamVideo
import StreamVideoSwiftUI
import SwiftUI
import Combine

@MainActor
fileprivate func content() {
    container {
        let call = streamVideo.call(callType: "default", callId: "chat-123")
        let policy = VideoProximityPolicy()

        do {
            try call.addProximityPolicy(policy)
        } catch {
            log.error(error)
        }
    }

    container {
        let call = streamVideo.call(callType: "default", callId: "team-meet")
        let policy = SpeakerProximityPolicy()

        do {
            try call.addProximityPolicy(policy)
        } catch {
            log.error(error)
        }
    }

    container {
        let call = streamVideo.call(callType: "default", callId: "chat-123")
        let videoPolicy = VideoProximityPolicy()
        let speakerPolicy = SpeakerProximityPolicy()

        do {
            try call.addProximityPolicy(videoPolicy)
            try call.addProximityPolicy(speakerPolicy)
        } catch {
            log.error(error)
        }
    }
}
