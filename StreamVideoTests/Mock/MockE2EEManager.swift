//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
import StreamWebRTC

final class MockE2EEManager: E2EEManager, @unchecked Sendable {
    private let queue = UnfairQueue()
    private var _encryptCalls: [(codec: String?, trackType: TrackType?)] = []
    private var _decryptCalls: [(userId: String, trackType: TrackType?)] = []

    var encryptCalls: [(codec: String?, trackType: TrackType?)] {
        queue.sync { _encryptCalls }
    }

    var decryptCalls: [(userId: String, trackType: TrackType?)] {
        queue.sync { _decryptCalls }
    }

    func encrypt(
        _ sender: RTCRtpSender,
        codec: String?,
        trackType: TrackType?
    ) throws {
        queue.sync { _encryptCalls.append((codec, trackType)) }
    }

    func decrypt(
        _ receiver: RTCRtpReceiver,
        userId: String,
        trackType: TrackType?
    ) throws {
        queue.sync { _decryptCalls.append((userId, trackType)) }
    }
}
