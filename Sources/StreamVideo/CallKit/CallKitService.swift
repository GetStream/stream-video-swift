//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CallKit
import Combine
import Foundation

/// `CallKitService` manages interactions with the CallKit framework,
/// facilitating VoIP calls in an application.
open class CallKitService: NSObject, CXProviderDelegate, @unchecked Sendable {
    /// Represents the state of a call.
    public enum State { case idle, joining, inCall }

    /// The currently active StreamVideo client.
    /// - Important: We need to update it whenever a user logins.
    public var streamVideo: StreamVideo? {
        didSet { didUpdate(streamVideo) }
    }

    /// The unique identifier for the call.
    open var callId: String = ""
    /// The type of call.
    open var callType: String = ""
    /// The icon data for the call template.
    open var iconTemplateImageData: Data?

    /// The call controller used for managing calls.
    open internal(set) lazy var callController = CXCallController()
    /// The call provider responsible for handling call-related actions.
    open internal(set) lazy var callProvider = buildProvider()

    private weak var call: Call?
    private var state: State = .idle
    private var callKitId: UUID?
    private var createdBy: User?
    private var ringingTimer: Foundation.Timer?
    private var callEventsSubscription: Task<Void, Never>?

    private var callEndedNotificationCancellable: AnyCancellable?
    private var ringingTimerCancellable: AnyCancellable?

    /// Initializes the `CallKitService` instance.
    override public init() {
        super.init()

        // Subscribe to the call ended notification.
        callEndedNotificationCancellable = NotificationCenter
            .default
            .publisher(for: Notification.Name(CallNotification.callEnded))
            .sink { [weak self] _ in self?.callEnded() }

        // Subscribe to call events.
        subscribeToCallEvents()
    }

    /// Reports an incoming call to the CallKit framework.
    ///
    /// - Parameters:
    ///   - cid: The call ID.
    ///   - localizedCallerName: The localized caller name.
    ///   - callerId: The caller's identifier.
    ///   - completion: A closure to be called upon completion.
    open func reportIncomingCall(
        _ cid: String,
        localizedCallerName: String,
        callerId: String,
        completion: @escaping (Error?) -> Void
    ) {
        let callUpdate = buildCallUpdate(
            cid: cid,
            localizedCallerName: localizedCallerName,
            callerId: callerId
        )

        let callUUID = UUID()
        callKitId = callUUID

        callProvider.reportNewIncomingCall(
            with: callUUID,
            update: callUpdate,
            completion: completion
        )

        log.debug(
            "Reporting VoIP incoming call with callKitId:\(callUUID) cid:\(cid) callerId:\(callerId) callerName:\(localizedCallerName)."
        )

        guard let streamVideo else {
            log.warning("CallKit operation:reportIncomingCall cannot be fulfilled because StreamVideo is nil.")
            callEnded()
            return
        }

        Task {
            do {
                if streamVideo.state.connection != .connected {
                    let result = await Task { @MainActor in
                        try await streamVideo.connect()
                    }.result

                    switch result {
                    case .success:
                        break
                    case let .failure(failure):
                        throw failure
                    }
                }

                let call = streamVideo.call(callType: callType, callId: callId)
                let callState = try await call.get()

                if streamVideo.state.ringingCall?.cId != call.cId {
                    Task { @MainActor in
                        streamVideo.state.ringingCall = call
                    }
                }

                switch state {
                case .idle:
                    if !checkIfCallWasHandled(callState: callState) {
                        setUpRingingTimer(for: callState)
                        state = .joining
                    } else {
                        log.debug(
                            """
                            Rejecting VoIP incoming call with callKitId:\(callUUID)
                            cid:\(cid) callerId:\(callerId) callerName:\(localizedCallerName)
                            as it has been handled. CallKit state is \(state).
                            """
                        )
                        callEnded()
                    }
                default:
                    log.debug("No action after reporting incoming VoIP call as current CallKit state is \(state).")
                }
            } catch {
                callEnded()
            }
        }
    }

    /// Handles the event when a call is accepted.
    ///
    /// - Parameter response: The call accepted event.
    open func callAccepted(_ response: CallAcceptedEvent) {
        guard callId == response.call.id, let callKitId else {
            return
        }
        Task {
            do {
                // Update call state to inCall and send the answer call action.
                try await requestTransaction(CXAnswerCallAction(call: callKitId))
            } catch {
                log.error(error)
            }
        }
    }

    /// Handles the event when a call is rejected.
    ///
    /// - Parameter response: The call rejected event.
    open func callRejected(_ response: CallRejectedEvent) {
        let isCurrentUserRejection = response.user.id == streamVideo?.user.id
        let isCallCreatorRejection = response.user.id == createdBy?.id

        guard
            callId == response.call.id,
            (isCurrentUserRejection || isCallCreatorRejection),
            let callKitId
        else {
            return
        }
        Task {
            do {
                // End the call if rejected.
                try await requestTransaction(CXEndCallAction(call: callKitId))
            } catch {
                log.error(error)
            }
        }
    }

    /// Handles the event when a call ends.
    open func callEnded() {
        guard let callKitId else {
            return
        }
        Task {
            do {
                // End the call.
                try await requestTransaction(CXEndCallAction(call: callKitId))
            } catch {
                log.error(error)
            }
        }
    }

    /// Handles the event when a participant leaves the call.
    ///
    /// - Parameter response: The call session participant left event.
    open func callParticipantLeft(
        _ response: CallSessionParticipantLeftEvent
    ) {
        /// We listen for the event so in the case we are the only ones remaining
        /// in the call, we leave.
        Task { @MainActor in
            if let call, call.state.participants.count == 1 {
                callEnded()
            }
        }
    }

    // MARK: - CXProviderDelegate

    /// Called when the provider has been reset. Delegates must respond to this callback by cleaning up
    /// all internal call state (disconnecting communication channels, releasing network resources, etc.).
    /// This callback can be treated as a request to end all calls without the need to respond to any actions
    open func providerDidReset(_ provider: CXProvider) {
        log.debug("CXProvider didReset.")
    }

    open func provider(
        _ provider: CXProvider,
        perform action: CXAnswerCallAction
    ) {
        guard !callId.isEmpty else {
            return action.fail()
        }

        ringingTimerCancellable?.cancel()
        ringingTimerCancellable = nil

        guard state != .inCall else {
            action.fail()
            return
        }

        guard let streamVideo else {
            log.warning("CallKit operation:answerCall cannot be fulfilled because StreamVideo is nil.")
            callEnded()
            return
        }

        Task { @MainActor in
            state = .joining
            log.debug("Answering VoIP incoming call with callId:\(callId) callType:\(callType).")
            let call = streamVideo.call(callType: callType, callId: callId)

            do {
                try await call.accept()
            } catch {
                log.error(error)
            }

            do {
                try await call.join()
                self.call = call
                state = .inCall
                action.fulfill()
            } catch {
                log.error(error)
                self.call?.leave()
                self.call = nil
                state = .idle
                log.error(error)
                action.fail()
            }
        }
    }

    open func provider(
        _ provider: CXProvider,
        perform action: CXEndCallAction
    ) {
        callKitId = nil
        ringingTimerCancellable?.cancel()
        ringingTimerCancellable = nil
        Task {
            if call == nil, !callId.isEmpty {
                call = streamVideo?.call(callType: callType, callId: callId)
                log.debug("Rejecting VoIP incoming call with callId:\(callId) callType:\(callType).")
            }
            try await call?.reject()
            call = nil
            createdBy = nil
            state = .idle
            action.fulfill()
        }
    }

    // MARK: - Helpers

    /// Requests a transaction asynchronously.
    ///
    /// - Parameter transaction: The transaction to be requested.
    /// - Throws: An error if the request fails.
    open func requestTransaction(
        _ action: CXAction
    ) async throws {
        try await callController.requestTransaction(with: action)
    }

    /// Checks whether the call was handled.
    ///
    /// - Parameter callState: The state of the call.
    /// - Returns: A boolean value indicating whether the call was handled.
    open func checkIfCallWasHandled(callState: GetCallResponse) -> Bool {
        guard let streamVideo else {
            log.warning("CallKit operation:\(#function) cannot be fulfilled because StreamVideo is nil.")
            return false
        }

        let currentUserId = streamVideo.user.id
        let acceptedBy = callState.call.session?.acceptedBy ?? [:]
        let rejectedBy = callState.call.session?.rejectedBy ?? [:]
        let isAccepted = acceptedBy[currentUserId] != nil
        let isRejected = rejectedBy[currentUserId] != nil
        let isRejectedByEveryoneElse = rejectedBy.keys.filter { $0 != currentUserId }.count == (callState.members.count - 1)
        return isAccepted || isRejected || isRejectedByEveryoneElse
    }

    /// Sets up a ringing timer for the call.
    ///
    /// - Parameter callState: The state of the call.
    open func setUpRingingTimer(for callState: GetCallResponse) {
        createdBy = callState.call.createdBy.toUser
        let timeout = TimeInterval(callState.call.settings.ring.autoCancelTimeoutMs / 1000)
        ringingTimerCancellable = Foundation.Timer.publish(
            every: timeout,
            on: .main,
            in: .default
        )
        .autoconnect()
        .sink { [weak self] _ in
            log.debug("Detected ringing timeout, hanging up...")
            self?.callEnded()
        }
    }

    /// A method that's being called every time the StreamVideo instance is getting updated.
    /// - Parameter streamVideo: The new StreamVideo instance (nil if none)
    open func didUpdate(_ streamVideo: StreamVideo?) {
        subscribeToCallEvents()
    }

    // MARK: - Private helpers

    private func subscribeToCallEvents() {
        callEventsSubscription?.cancel()
        callEventsSubscription = nil

        guard let streamVideo else {
            log.warning("CallKit operation:\(#function) cannot be fulfilled because StreamVideo is nil.")
            return
        }

        callEventsSubscription = Task {
            for await event in streamVideo.subscribe() {
                switch event {
                case .typeCallEndedEvent:
                    callEnded()
                case let .typeCallAcceptedEvent(response):
                    callAccepted(response)
                case let .typeCallRejectedEvent(response):
                    callRejected(response)
                case let .typeCallSessionParticipantLeftEvent(response):
                    callParticipantLeft(response)
                default:
                    break
                }
            }
        }
    }

    private func buildProvider(
        supportsVideo: Bool = true,
        supportedHandleTypes: Set<CXHandle.HandleType> = [.generic]
    ) -> CXProvider {
        let configuration = {
            if #available(iOS 14.0, *) {
                return CXProviderConfiguration()
            } else {
                return CXProviderConfiguration(localizedName: "video.provider.configuration")
            }
        }()
        configuration.supportsVideo = supportsVideo
        configuration.supportedHandleTypes = supportedHandleTypes
        configuration.iconTemplateImageData = iconTemplateImageData

        let provider = CXProvider(configuration: configuration)
        provider.setDelegate(self, queue: nil)
        return provider
    }

    private func buildCallUpdate(
        cid: String,
        localizedCallerName: String,
        callerId: String
    ) -> CXCallUpdate {
        let update = CXCallUpdate()
        let idComponents = cid.components(separatedBy: ":")
        if idComponents.count >= 2 {
            callId = idComponents[1]
            callType = idComponents[0]
        }

        update.localizedCallerName = localizedCallerName
        update.remoteHandle = CXHandle(type: .generic, value: callerId)
        update.hasVideo = true

        return update
    }
}

extension CallKitService: InjectionKey {
    /// Provides the current instance of `CallKitService`.
    public static var currentValue: CallKitService = .init()
}

extension InjectedValues {
    /// A property wrapper to access the `CallKitService` instance.
    public var callKitService: CallKitService {
        get { Self[CallKitService.self] }
        set { Self[CallKitService.self] = newValue }
    }
}
