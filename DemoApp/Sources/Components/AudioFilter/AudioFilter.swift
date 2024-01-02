//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

protocol AudioFilter {

    func applyEffect(to audioBuffer: inout RTCAudioBuffer)
}
