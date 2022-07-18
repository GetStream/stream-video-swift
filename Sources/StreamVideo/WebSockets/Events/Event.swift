//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

/// An `Event` object representing an event in the chat system.
public protocol Event: ProtoModel {}

extension Event {
    var name: String {
        String(describing: Self.self)
    }
}

extension Stream_Video_WebsocketEvent: Event {}
extension Stream_Video_Healthcheck: Event {}
extension Stream_Video_CallRinging: Event {}
extension Stream_Video_CallCreated: Event {}
extension Stream_Video_CallUpdated: Event {}
extension Stream_Video_CallEnded: Event {}
extension Stream_Video_CallDeleted: Event {}
extension Stream_Video_UserUpdated: Event {}
extension Stream_Video_ParticipantInvited: Event {}
extension Stream_Video_ParticipantUpdated: Event {}
extension Stream_Video_ParticipantDeleted: Event {}
extension Stream_Video_ParticipantJoined: Event {}
extension Stream_Video_ParticipantLeft: Event {}
extension Stream_Video_BroadcastStarted: Event {}
extension Stream_Video_BroadcastEnded: Event {}
extension Stream_Video_AuthPayload: Event {}
