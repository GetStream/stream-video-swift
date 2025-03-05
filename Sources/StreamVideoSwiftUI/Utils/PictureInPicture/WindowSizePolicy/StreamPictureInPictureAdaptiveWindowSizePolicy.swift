//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// An adaptive window size policy for Picture-in-Picture (PiP) views.
final class StreamPictureInPictureAdaptiveWindowSizePolicy: PictureInPictureWindowSizePolicy, @unchecked Sendable {

    /// The current size of the track to be displayed in the PiP window.
    var trackSize: CGSize = .zero {
        didSet {
            // Only update the controller's preferred content size if the track size has changed and is not zero.
            guard trackSize != oldValue, trackSize != .zero else {
                return
            }
            Task { @MainActor in
                controller?.preferredContentSize = trackSize
            }
        }
    }

    /// The controller that manages the PiP view.
    weak var controller: StreamAVPictureInPictureViewControlling?

    /// Initializes a new instance of the adaptive window size policy.
    init() {}
}
