//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// A final class that implements the `Stream_Video_Sfu_Signal_SignalServer` protocol and
/// conforms to the `Sendable` protocol.
///
/// This class is marked as `@unchecked Sendable` to indicate that it's the developer's responsibility to
/// ensure thread safety.
class SFUSignalService: Stream_Video_Sfu_Signal_SignalServer, @unchecked Sendable {

    /// A PassthroughSubject that emits `SignalServerEvent` events and never fails.
    ///
    /// This subject can be used to publish events related to the SFU (Selective Forwarding Unit) signal
    /// service. Subscribers can receive these events to react to various signal server activities.
    let subject: PassthroughSubject<SignalServerEvent, Never> = .init()
}
