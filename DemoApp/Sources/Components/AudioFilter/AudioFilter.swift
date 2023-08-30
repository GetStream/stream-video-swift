//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import WebRTC

protocol AudioFilter {

    func applyEffect(to audioBuffer: inout RTCAudioBuffer)
}
