//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

// New protocol definition
protocol SignalServerEvent: CustomStringConvertible {}

extension Stream_Video_Sfu_Signal_SignalServer {
    private enum AssociatedKeys {
        static var subjectKey = "Stream_Video_Sfu_Signal_SignalServerSubjectKey"
    }

    var subject: PassthroughSubject<SignalServerEvent, Never> {
        withUnsafePointer(to: &AssociatedKeys.subjectKey) { key in
            if let existing = objc_getAssociatedObject(
                self,
                key
            ) as? PassthroughSubject<SignalServerEvent, Never> {
                return existing
            } else {
                let newValue = PassthroughSubject<SignalServerEvent, Never>()
                objc_setAssociatedObject(
                    self,
                    key,
                    newValue,
                    .OBJC_ASSOCIATION_RETAIN_NONATOMIC
                )
                return newValue
            }
        }
    }
}

// Extensions for return types
extension Stream_Video_Sfu_Signal_SetPublisherRequest: SignalServerEvent {
    var description: String {
        """
        Type: \(type(of: self))
            sdp: \(sdp)
            sessionID: \(sessionID)
            tracks: \(tracks)
        """
    }
}

extension Stream_Video_Sfu_Signal_SetPublisherResponse: SignalServerEvent {
    var description: String {
        """
        Type: \(type(of: self))
            sdp: \(sdp)
            sessionID: \(sessionID)
            iceRestart: \(iceRestart)
            error: \(error)
        """
    }
}

extension Stream_Video_Sfu_Signal_SendAnswerRequest: SignalServerEvent {
    var description: String {
        """
        Type: \(type(of: self))
            peerType: \(peerType)
            sdp: \(sdp)
            sessionID: \(sessionID)
        """
    }
}

extension Stream_Video_Sfu_Signal_SendAnswerResponse: SignalServerEvent {
    var description: String {
        """
        Type: \(type(of: self))
            error: \(error)
        """
    }
}

extension Stream_Video_Sfu_Signal_ICETrickleResponse: SignalServerEvent {
    var description: String {
        """
        Type: \(type(of: self))
            error: \(error)
        """
    }
}

extension Stream_Video_Sfu_Signal_UpdateSubscriptionsRequest: SignalServerEvent {
    var description: String {
        """
        Type: \(type(of: self))
            sessionID: \(sessionID)
            tracks: \(tracks)
        """
    }
}

extension Stream_Video_Sfu_Signal_UpdateSubscriptionsResponse: SignalServerEvent {
    var description: String {
        """
        Type: \(type(of: self))
            error: \(error)
        """
    }
}

extension Stream_Video_Sfu_Signal_UpdateMuteStatesRequest: SignalServerEvent {
    var description: String {
        """
        Type: \(type(of: self))
            sessionID: \(sessionID)
            \(muteStates.map(\.description).joined(separator: "\n"))
        """
    }
}

extension Stream_Video_Sfu_Signal_TrackMuteState: SignalServerEvent {
    var description: String {
        """
        Type: \(type(of: self))
            trackType: \(trackType)
            muted: \(muted)
        """
    }
}

extension Stream_Video_Sfu_Signal_UpdateMuteStatesResponse: SignalServerEvent {
    var description: String {
        """
        Type: \(type(of: self))
            error: \(error)
        """
    }
}

extension Stream_Video_Sfu_Signal_ICERestartResponse: SignalServerEvent {
    var description: String {
        """
        Type: \(type(of: self))
            error: \(error)
        """
    }
}

extension Stream_Video_Sfu_Signal_SendStatsResponse: SignalServerEvent {
    var description: String {
        """
        Type: \(type(of: self))
            error: \(error)
        """
    }
}

extension Stream_Video_Sfu_Signal_StartNoiseCancellationResponse: SignalServerEvent {
    var description: String {
        """
        Type: \(type(of: self))
            error: \(error)
        """
    }
}

extension Stream_Video_Sfu_Signal_StopNoiseCancellationResponse: SignalServerEvent {
    var description: String {
        """
        Type: \(type(of: self))
            error: \(error)
        """
    }
}
