//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Combine

public final class CallSettings: ObservableObject, Sendable {
    public let audioOn: Bool
    public let videoOn: Bool
    public let speakerOn: Bool
    public let cameraPosition: CameraPosition
        
    public init(
        audioOn: Bool = true,
        videoOn: Bool = true,
        speakerOn: Bool = true,
        cameraPosition: CameraPosition = .front
    ) {
        self.audioOn = audioOn
        self.videoOn = videoOn
        self.speakerOn = speakerOn
        self.cameraPosition = cameraPosition
    }
    
    var shouldPublish: Bool {
        audioOn || videoOn
    }
    
    func withUpdatedCameraPosition(_ cameraPosition: CameraPosition) -> CallSettings {
        CallSettings(
            audioOn: audioOn,
            videoOn: videoOn,
            speakerOn: speakerOn,
            cameraPosition: cameraPosition
        )
    }
}

public enum CameraPosition: Sendable {
    case front
    case back
    
    func next() -> CameraPosition {
        self == .front ? .back : .front
    }
}
