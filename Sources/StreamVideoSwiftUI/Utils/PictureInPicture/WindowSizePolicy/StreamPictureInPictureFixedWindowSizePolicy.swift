//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// A fixed window size policy for Picture-in-Picture (PiP) views.
final class StreamPictureInPictureFixedWindowSizePolicy: PictureInPictureWindowSizePolicy {

    /// The current size of the track to be displayed in the PiP window. This is not used in this policy.
    var trackSize: CGSize = .zero

    /// The controller that manages the PiP view.
    weak var controller: (any StreamAVPictureInPictureViewControlling)? {
        didSet {
            // Set the preferred content size of the controller to the fixed size.
            controller?.preferredContentSize = fixedSize
        }
    }

    /// The fixed size for the PiP window.
    private let fixedSize: CGSize

    /// Initializes a new instance of the fixed window size policy with a specified fixed size.
    /// - Parameter fixedSize: The fixed size for the PiP window. Default is 640x480.
    init(_ fixedSize: CGSize = .init(width: 640, height: 480)) {
        self.fixedSize = fixedSize
    }
}
