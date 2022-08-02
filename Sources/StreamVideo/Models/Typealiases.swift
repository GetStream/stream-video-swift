//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import LiveKit

public typealias VideoTrackPublication = TrackPublication
public typealias StreamVideoTrack = VideoTrack
public typealias StreamTrackPublishState = TrackPublishState
public typealias VideoConnectionQuality = ConnectionQuality
public typealias StreamRemoteTrackPublication = RemoteTrackPublication

public struct CallType {
    var name: String
    
    public init(name: String) {
        self.name = name
    }
}
