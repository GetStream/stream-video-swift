//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

/// An `Event` object representing an event in the chat system.
public protocol Event {}

public protocol SendableEvent: Event, ProtoModel {}

extension Event {
    var name: String {
        String(describing: Self.self)
    }
}

extension Stream_Video_WebsocketClientEvent: SendableEvent {}
extension Stream_Video_WebsocketEvent: SendableEvent {}
extension Stream_Video_Healthcheck: SendableEvent {}
extension Stream_Video_CallCreated: SendableEvent {}
extension Stream_Video_CallCancelled: SendableEvent {}
extension Stream_Video_CallRejected: SendableEvent {}
extension Stream_Video_CallAccepted: SendableEvent {}
extension Stream_Video_CallUpdated: SendableEvent {}
extension Stream_Video_CallEnded: SendableEvent {}
extension Stream_Video_CallDeleted: SendableEvent {}
extension Stream_Video_UserUpdated: SendableEvent {}
extension Stream_Video_BroadcastStarted: SendableEvent {}
extension Stream_Video_BroadcastEnded: SendableEvent {}
extension Stream_Video_AuthPayload: SendableEvent {}
extension Stream_Video_RecordingStarted: SendableEvent {}
extension Stream_Video_RecordingStopped: SendableEvent {}
extension Stream_Video_CallMembersDeleted: SendableEvent {}
extension Stream_Video_CallMembersUpdated: SendableEvent {}
extension Stream_Video_CallCustom: SendableEvent {}
