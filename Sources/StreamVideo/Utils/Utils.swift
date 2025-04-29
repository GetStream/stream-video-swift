//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

internal extension DispatchQueue {

    static let sdk = DispatchQueue(label: "StreamVideoSDK", qos: .userInitiated)
}

func postNotification(
    with name: String,
    object: Any? = nil,
    userInfo: [AnyHashable: Any] = [:]
) {
    NotificationCenter.default.post(
        name: NSNotification.Name(name),
        object: object,
        userInfo: userInfo
    )
}

public func callCid(from callId: String, callType: String) -> String {
    "\(callType):\(callId)"
}

public enum CallNotification {
    public static let callEnded = "StreamVideo.Call.Ended"
    public static let participantLeft = "StreamVideo.Call.ParticipantLeft"
}

struct EventHandler {
    var handler: ((WrappedEvent) -> Void)
    var cancel: () -> Void
}

func executeOnMain(_ task: @Sendable @escaping @MainActor() -> Void) {
    Task {
        await task()
    }
}

func infoPlistValue(for key: String) -> String? {
    Bundle.main.infoDictionary?[key] as? String
}

extension InternetConnection: InjectionKey {
    /// The current value of the internet connection monitor.
    ///
    /// This property provides a default implementation of the
    /// `InternetConnection` with a default monitor.
    public static var currentValue: InternetConnectionProtocol = InternetConnection(monitor: InternetConnection.Monitor())
}

public extension InjectedValues {
    /// The current value of the internet connection monitor as a protocol type.
    ///
    /// This property allows for dependency injection using the protocol type,
    /// providing more flexibility in testing and modular design.
    var internetConnectionObserver: InternetConnectionProtocol {
        get { Self[InternetConnection.self] }
        set { Self[InternetConnection.self] = newValue }
    }
}
