//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

@MainActor
final class LivestreamPlayerViewModel: ObservableObject {
    @Published private(set) var fullScreen = false
    @Published private(set) var controlsShown = false {
        didSet {
            if controlsShown {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                    guard let self else { return }
                    if !self.streamPaused {
                        self.controlsShown = false
                    }
                }
            }
        }
    }

    @Published private(set) var streamPaused = false
    @Published private(set) var loading = false
    @Published private(set) var muted: Bool
    @Published var errorShown = false
    
    private var mutedOnJoin = false
    
    private let streamVideo: StreamVideo
    
    let call: Call
    let showParticipantCount: Bool
    
    private let formatter = DateComponentsFormatter()
    
    init(
        token: String,
        muted: Bool = false,
        showParticipantCount: Bool = true
    ) throws {
        guard let jwtPayload = token.jwtPayload,
              let apiKey = jwtPayload["api_key"] as? String,
              let userId = jwtPayload["user_id"] as? String,
              let callCid = jwtPayload["call"] as? String
        else {
            throw ClientError.InvalidToken()
        }
        
        let components = callCid.components(separatedBy: ":")
        guard components.count >= 2 else { throw ClientError.InvalidToken() }
    
        let type = components[0]
        let id = components[1]
        
        streamVideo = StreamVideo(
            apiKey: apiKey,
            user: .init(id: userId),
            token: UserToken(rawValue: token)
        )
        
        let call = streamVideo.call(callType: type, callId: id)
        self.call = call
        self.showParticipantCount = showParticipantCount
        self.muted = muted
        formatter.unitsStyle = .positional
    }
    
    init(
        streamVideo: StreamVideo,
        call: Call,
        token: String,
        muted: Bool = false,
        showParticipantCount: Bool = true
    ) {
        self.streamVideo = streamVideo
        self.call = call
        self.showParticipantCount = showParticipantCount
        self.muted = muted
        streamVideo.update(token: UserToken(rawValue: token))
        formatter.unitsStyle = .positional
    }
    
    var hosts: [CallParticipant] {
        call.state.participants.filter { $0.roles.contains("host") }
    }
    
    func update(fullScreen: Bool) {
        self.fullScreen = fullScreen
    }
    
    func update(controlsShown: Bool) {
        self.controlsShown = controlsShown
    }
    
    func update(streamPaused: Bool) {
        self.streamPaused = streamPaused
    }
    
    func duration(from state: CallState) -> String? {
        guard state.duration > 0 else { return nil }
        return formatter.string(from: state.duration)
    }
    
    func muteLivestreamOnJoin() {
        guard !mutedOnJoin else { return }
        Task {
            try await call.speaker.disableAudioOutput()
            mutedOnJoin = true
        }
    }
    
    func toggleAudioOutput() {
        Task {
            if !muted {
                try await call.speaker.disableAudioOutput()
            } else {
                try await call.speaker.enableAudioOutput()
            }
            muted.toggle()
        }
    }
    
    func joinLivestream() {
        Task {
            do {
                loading = true
                try await call.join(callSettings: CallSettings(audioOn: false, videoOn: false))
                loading = false
            } catch {
                errorShown = true
                loading = false
                log.error("Error joining livestream")
            }
        }
    }
    
    func leaveLivestream() {
        call.leave()
    }
}

internal extension String {
    var jwtPayload: [String: Any]? {
        let parts = split(separator: ".")

        if parts.count == 3,
           let payloadData = jwtDecodeBase64(String(parts[1])),
           let json = (try? JSONSerialization.jsonObject(with: payloadData)) as? [String: Any] {
            return json
        }

        return nil
    }

    func jwtDecodeBase64(_ input: String) -> Data? {
        let removeEndingCount = input.count % 4
        let ending = removeEndingCount > 0 ? String(repeating: "=", count: 4 - removeEndingCount) : ""
        let base64 = input.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/") + ending

        return Data(base64Encoded: base64)
    }
}
