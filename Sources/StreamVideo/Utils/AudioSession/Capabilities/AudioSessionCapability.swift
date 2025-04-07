//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation

public protocol AudioSessionCapability {

    var identifier: ObjectIdentifier { get }
}

protocol _AudioSessionCapability {
    var actionDispatcher: ((CallSettings) async -> Void)? { get set }
    var audioSession: StreamAudioSession? { get set }
}
