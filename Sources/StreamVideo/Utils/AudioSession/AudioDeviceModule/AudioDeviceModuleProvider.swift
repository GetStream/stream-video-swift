//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Looks up the live ``AudioDeviceModule`` after the peer-connection
/// factory has built it.
///
/// The factory creates the module lazily, so apply-time lookup is
/// required. Call ``audioDeviceModule()`` when applying a capture policy,
/// not at adapter construction.
struct AudioDeviceModuleProvider: Sendable {

    private let resolve: @Sendable () -> AudioDeviceModule

    /// - Parameter resolve: Looked up at apply time, not construction.
    init(_ resolve: @escaping @Sendable () -> AudioDeviceModule) {
        self.resolve = resolve
    }

    /// The current WebRTC audio device module for this factory.
    func audioDeviceModule() -> AudioDeviceModule {
        resolve()
    }
}
