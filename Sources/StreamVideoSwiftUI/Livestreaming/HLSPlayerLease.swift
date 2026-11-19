//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation

/// A claim on the shared player of a call. Release it when the view or
/// control that took it goes away. Releasing more than once is a no-op.
@MainActor
final class HLSPlayerLease {

    /// The player shared by every lease of the call.
    let player: AVPlayer

    private let id = UUID()
    private weak var store: HLSPlayerStore?
    private let callId: String

    init(player: AVPlayer, callId: String, store: HLSPlayerStore) {
        self.player = player
        self.callId = callId
        self.store = store
    }

    /// Gives the claim back. The player stops when no claim is left.
    func release() {
        store?.release(leaseId: id, callId: callId)
    }

    var leaseId: UUID { id }
}
