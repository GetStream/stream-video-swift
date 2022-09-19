//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Combine

public final class CallSettings: ObservableObject, Sendable {
    public let audioOn: Bool
    public let videoOn: Bool
    public let speakerOn: Bool
    public let cameraPosition: CameraPosition
    
    private let useLocalhost = false
    
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
    
    // Just temporary solution.
    var url: String {
        if useLocalhost {
            return "http://192.168.0.132:3031/twirp"
        } else {
            return "https://sfu2.fra1.gtstrm.com/rpc/twirp"
        }
    }
}

public enum CameraPosition: Sendable {
    case front
    case back
    
    func next() -> CameraPosition {
        self == .front ? .back : .front
    }
}
