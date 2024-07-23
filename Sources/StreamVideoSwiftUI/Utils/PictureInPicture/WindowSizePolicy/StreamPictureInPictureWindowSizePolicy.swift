//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// Protocol defining the policy for determining the window size of a Picture-in-Picture (PiP) view.
protocol PictureInPictureWindowSizePolicy {
    /// The current size of the track to be displayed in the PiP window.
    var trackSize: CGSize { get set }

    /// The controller that manages the PiP view.
    var controller: StreamAVPictureInPictureViewControlling? { get set }
}
