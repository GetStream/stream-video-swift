//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
import StreamWebRTC

extension AVAudioSession {
    public var hasEarpiece: Bool {
        availableInputs?
            .lazy
            .compactMap(\.portType)
            .first { $0 == .builtInReceiver } != nil
    }
}

extension RTCAudioSession {
    var hasEarpiece: Bool {
        session.hasEarpiece
    }
}
