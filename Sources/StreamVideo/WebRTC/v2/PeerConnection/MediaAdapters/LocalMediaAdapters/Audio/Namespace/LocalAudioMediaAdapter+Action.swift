//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

extension LocalAudioMediaAdapter.Namespace {

    enum StoreAction: Sendable {
        case setCallSettings(CallSettings.Audio)
        case setOwnCapabilities(Set<OwnCapability>)
        case setPublishingState(State.PublishingState, availableTrackStates: [State.TrackState])
        case setPublishOptions([PublishOptions.AudioPublishOptions])
        case setAudioBitrateAndMediaConstraints(audioBitrate: AudioBitrate, mediaConstraints: RTCMediaConstraints)
    }
}
