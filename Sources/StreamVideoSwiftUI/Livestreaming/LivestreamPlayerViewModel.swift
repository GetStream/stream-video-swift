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
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: { [weak self] in
                    guard let self else { return }
                    if !self.streamPaused {
                        self.controlsShown = false
                    }
                })
            }
        }
    }
    @Published private(set) var streamPaused = false
    @Published private(set) var loading = false
    @Published private(set) var muted: Bool
    @Published var errorShown = false
    
    private var mutedOnJoin = false
    
    let call: Call
    let showParticipantCount: Bool
    
    private let formatter = DateComponentsFormatter()
    
    init(
        type: String,
        id: String,
        muted: Bool = false,
        showParticipantCount: Bool = true
    ) {
        let call = InjectedValues[\.streamVideo].call(callType: type, callId: id)
        self.call = call
        self.showParticipantCount = showParticipantCount
        self.muted = muted
        formatter.unitsStyle = .positional
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
        guard state.duration > 0  else { return nil }
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
