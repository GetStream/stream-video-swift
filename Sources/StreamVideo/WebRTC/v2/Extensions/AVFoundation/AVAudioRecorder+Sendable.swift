//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Combine

#if compiler(>=6.0)
extension AVAudioRecorder: @retroactive @unchecked Sendable {}
#else
extension AVAudioRecorder: @unchecked Sendable {}
#endif
