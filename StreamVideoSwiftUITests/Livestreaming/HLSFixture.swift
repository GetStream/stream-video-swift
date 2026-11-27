//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
@testable import StreamVideoSwiftUI

/// A `LivestreamPlayer` whose call reports a playback type and whose HLS
/// player is a mock.
struct HLSFixture {
    let subject: LivestreamPlayer<DefaultViewFactory>
    let player: MockHLSPlayer
    let callController: MockCallController
}
