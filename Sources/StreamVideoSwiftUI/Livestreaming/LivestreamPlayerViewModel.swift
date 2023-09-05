//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

@MainActor
class LivestreamPlayerViewModel: ObservableObject {
    @Published private(set) var fullScreen = false
    @Published private(set) var controlsShown = false {
        didSet {
            if controlsShown {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: { [weak self] in
                    guard let self else { return }
                    if !streamPaused {
                        controlsShown = false
                    }
                })
            }
        }
    }
    @Published private(set) var streamPaused = false
    
    private let formatter = DateComponentsFormatter()
    
    init() {
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
}
