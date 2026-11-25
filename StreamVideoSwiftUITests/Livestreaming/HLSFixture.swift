//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
@testable import StreamVideoSwiftUI

/// A `LivestreamPlayer` whose call reports a playback type and whose HLS
/// player is a spy.
struct HLSFixture {
    let subject: LivestreamPlayer<DefaultViewFactory>
    let player: HLSSpyPlayer
    let store: HLSPlayerStore
    let callController: MockCallController
    /// The claim the renderer holds on the player.
    let lease: HLSPlayerLease?
}
