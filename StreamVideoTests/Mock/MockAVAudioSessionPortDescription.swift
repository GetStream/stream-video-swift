//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation

final class MockAVAudioSessionPortDescription: AVAudioSessionPortDescription, @unchecked Sendable {

    var stubPortType: AVAudioSession.Port
    override var portType: AVAudioSession.Port { stubPortType }

    var stubPortName: String
    override var portName: String { stubPortName }

    var stubUid: String
    override var uid: String { stubUid }

    var stubHasHardwareVoiceCallProcessing: Bool
    override var hasHardwareVoiceCallProcessing: Bool { stubHasHardwareVoiceCallProcessing }

    var stubIsSpatialAudioEnabled: Bool
    override var isSpatialAudioEnabled: Bool { stubIsSpatialAudioEnabled }

    var stubChannels: [AVAudioSessionChannelDescription]?
    override var channels: [AVAudioSessionChannelDescription]? { stubChannels }

    var stubDataSources: [AVAudioSessionDataSourceDescription]?
    override var dataSources: [AVAudioSessionDataSourceDescription]? { stubDataSources }

    var stubSelectedDataSource: AVAudioSessionDataSourceDescription?
    override var selectedDataSource: AVAudioSessionDataSourceDescription? { stubSelectedDataSource }

    var stubPreferredDataSource: AVAudioSessionDataSourceDescription?
    override var preferredDataSource: AVAudioSessionDataSourceDescription? { stubPreferredDataSource }

    init(
        portType: AVAudioSession.Port,
        portName: String = .unique,
        uid: String = UUID().uuidString,
        hasHardwareVoiceCallProcessing: Bool = false,
        isSpatialAudioEnabled: Bool = false,
        channels: [AVAudioSessionChannelDescription]? = nil,
        dataSources: [AVAudioSessionDataSourceDescription]? = nil,
        selectedDataSource: AVAudioSessionDataSourceDescription? = nil,
        preferredDataSource: AVAudioSessionDataSourceDescription? = nil
    ) {
        stubPortType = portType
        stubPortName = portName
        stubUid = uid
        stubHasHardwareVoiceCallProcessing = hasHardwareVoiceCallProcessing
        stubIsSpatialAudioEnabled = isSpatialAudioEnabled
        stubChannels = channels
        stubDataSources = dataSources
        stubSelectedDataSource = selectedDataSource
        stubPreferredDataSource = preferredDataSource
        super.init()
    }
}
