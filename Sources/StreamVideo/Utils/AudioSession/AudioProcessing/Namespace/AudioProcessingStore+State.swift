//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

extension AudioProcessingStore.Namespace {

    struct StoreState: Equatable, Sendable {
        var initializedSampleRate: Int
        var initializedChannels: Int
        var numberOfCaptureChannels: Int
        var capturePostProcessingDelegate: AudioCustomProcessingModule
        var audioFilter: AudioFilter?

        static let initial = StoreState(
            initializedSampleRate: 0,
            initializedChannels: 0,
            numberOfCaptureChannels: 0,
            capturePostProcessingDelegate: .init(),
            audioFilter: nil
        )

        static func == (
            lhs: AudioProcessingStore.Namespace.StoreState,
            rhs: AudioProcessingStore.Namespace.StoreState
        ) -> Bool {
            lhs.numberOfCaptureChannels == rhs.numberOfCaptureChannels
                && lhs.capturePostProcessingDelegate === rhs.capturePostProcessingDelegate
                && lhs.audioFilter?.id == rhs.audioFilter?.id
        }
    }
}
