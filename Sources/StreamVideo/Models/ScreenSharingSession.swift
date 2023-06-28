//
//  ScreenSharingSession.swift
//  StreamVideo
//
//  Created by Ilias Pavlidakis on 28/6/23.
//

import Foundation
import WebRTC

public struct ScreenSharingSession {
    public let track: RTCVideoTrack?
    public let participant: CallParticipant
}
