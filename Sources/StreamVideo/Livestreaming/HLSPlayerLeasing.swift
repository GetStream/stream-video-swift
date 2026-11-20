//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation

/// A claim on the shared player of one call.
///
/// Release the claim when the view that took it goes away. The player stops
/// when no claim is left. Releasing more than once does nothing.
@MainActor
public protocol HLSPlayerLeasing: AnyObject {
    /// The player shared by every claim of the call.
    var player: AVPlayer { get }

    /// Gives the claim back.
    func release()
}
