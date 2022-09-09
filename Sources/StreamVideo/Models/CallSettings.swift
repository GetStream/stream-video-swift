//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Combine

public class CallSettings: ObservableObject {
    public var audioOn: Bool
    public var videoOn: Bool
    public var speakerOn: Bool
    public var cameraPosition: CameraPosition = .front
    
    private var useLocalhost = false
    
    public init(
        audioOn: Bool = true,
        videoOn: Bool = true,
        speakerOn: Bool = true
    ) {
        self.audioOn = audioOn
        self.videoOn = videoOn
        self.speakerOn = speakerOn
    }
    
    var shouldPublish: Bool {
        audioOn || videoOn
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

public enum CameraPosition {
    case front
    case back
    
    func next() -> CameraPosition {
        self == .front ? .back : .front
    }
}
