//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import SwiftUI
import UIKit

/// A view that plays the HLS stream of a call.
///
/// The backend routes a viewer to HLS when it joins. Check
/// ``CallState/playbackType`` for `.hls`, and use this view instead of the
/// participant video views. Every renderer of the same call shows the same
/// player, so the stream is loaded once.
///
/// The renderer stays empty while the call does not play HLS, and fills as
/// soon as it does.
public struct HLSVideoRenderer: View {

    var call: Call
    var contentMode: UIView.ContentMode
    var onPlayerReady: (@MainActor () async -> Void)?

    /// Creates a renderer for the HLS stream of the call.
    /// - Parameters:
    ///   - call: The call that plays HLS.
    ///   - contentMode: How the video fits the view. Defaults to
    ///     `.scaleAspectFit`.
    public init(
        call: Call,
        contentMode: UIView.ContentMode = .scaleAspectFit
    ) {
        self.init(call: call, contentMode: contentMode, onPlayerReady: nil)
    }

    init(
        call: Call,
        contentMode: UIView.ContentMode,
        onPlayerReady: (@MainActor () async -> Void)?
    ) {
        self.call = call
        self.contentMode = contentMode
        self.onPlayerReady = onPlayerReady
    }

    public var body: some View {
        Representable(
            call: call,
            contentMode: contentMode,
            onPlayerReady: onPlayerReady
        )
    }
}
