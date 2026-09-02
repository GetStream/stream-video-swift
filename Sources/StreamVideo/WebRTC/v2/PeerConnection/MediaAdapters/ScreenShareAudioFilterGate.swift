//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Suspends live audio filters while in-app screenshare audio is running.
///
/// Call ``setActive(_:)`` on capture start (`true`) and stop (`false`).
/// Restoring does not override music: the applicator still suppresses the
/// live filter while the profile is
/// ``AudioBitrateProfile/musicHighQuality``.
struct ScreenShareAudioFilterGate: Sendable {

    private let setActiveHandler: @Sendable (Bool) -> Void

    /// - Parameter setActive: Called with `true` on start and `false` on stop.
    init(setActive: @escaping @Sendable (Bool) -> Void) {
        self.setActiveHandler = setActive
    }

    /// `true` suspends the live filter; `false` restores it unless music
    /// is still suppressing it.
    func setActive(_ isActive: Bool) {
        setActiveHandler(isActive)
    }
}
