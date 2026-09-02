//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Suspends live audio filters while in-app screenshare audio is running.
///
/// ReplayKit capture, the capturer factory, and
/// ``ScreenShareSessionProvider`` used to pass `((Bool) -> Void)?`. That
/// hid the contract (when to call, what `true` means) and made tests
/// assert on closures. This type holds the callback privately; call
/// ``setActive(_:)`` on capture start/stop. Restoring (`false`) does not
/// override music: the applicator still suppresses the live filter while
/// the profile is ``AudioBitrateProfile/musicHighQuality``.
struct ScreenShareAudioFilterGate: Sendable {

    private let setActiveHandler: @Sendable (Bool) -> Void

    init(setActive: @escaping @Sendable (Bool) -> Void) {
        self.setActiveHandler = setActive
    }

    /// `true` suspends the live filter; `false` restores it unless music
    /// is still suppressing it.
    func setActive(_ isActive: Bool) {
        setActiveHandler(isActive)
    }
}
