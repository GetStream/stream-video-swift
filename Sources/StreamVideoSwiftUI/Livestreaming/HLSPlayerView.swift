//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation
import UIKit

/// A view whose layer shows the frames of an `AVPlayer`.
public final class HLSPlayerView: UIView {

    override public class var layerClass: AnyClass { AVPlayerLayer.self }

    private var playerLayer: AVPlayerLayer {
        // The class property makes the layer an `AVPlayerLayer`.
        // swiftlint:disable:next force_cast
        layer as! AVPlayerLayer
    }

    var player: AVPlayer? {
        get { playerLayer.player }
        set { playerLayer.player = newValue }
    }

    var videoGravity: AVLayerVideoGravity {
        get { playerLayer.videoGravity }
        set { playerLayer.videoGravity = newValue }
    }
}
