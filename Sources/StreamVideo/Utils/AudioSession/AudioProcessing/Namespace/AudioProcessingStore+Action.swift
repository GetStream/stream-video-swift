//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

extension AudioProcessingStore.Namespace {

    enum StoreAction: StoreActionBoxProtocol, Sendable {
        case load
        case setInitializedConfiguration(sampleRate: Int, channels: Int)
        case setAudioFilter(AudioFilter?)
        case setNumberOfCaptureChannels(Int)
        case release
    }
}
