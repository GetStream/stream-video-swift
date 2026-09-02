//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Resolves the live ``AudioDeviceModule`` after the peer-connection
/// factory has created it.
///
/// The ADM does not exist when ``WebRTCStateAdapter`` is constructed; the
/// factory builds it lazily. This type holds that lookup so the bitrate
/// applicator never takes a bare `() -> AudioDeviceModule` through its
/// initializer. Call ``audioDeviceModule()`` at apply time.
struct AudioDeviceModuleProvider: Sendable {

    private let resolve: @Sendable () -> AudioDeviceModule

    init(_ resolve: @escaping @Sendable () -> AudioDeviceModule) {
        self.resolve = resolve
    }

    /// The current WebRTC audio device module for this factory.
    func audioDeviceModule() -> AudioDeviceModule {
        resolve()
    }
}
