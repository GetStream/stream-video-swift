//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Combine

public class CallSettings: ObservableObject {
    public var audioOn: Bool
    public var videoOn: Bool
    public var speakerOn: Bool
    
    public init(
        audioOn: Bool = true,
        videoOn: Bool = true,
        speakerOn: Bool = true
    ) {
        self.audioOn = audioOn
        self.videoOn = videoOn
        self.speakerOn = speakerOn
    }
}
