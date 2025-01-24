//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
import CallKit
import Combine
import Foundation

/// `CallKitService` manages interactions with the CallKit framework,
/// facilitating VoIP calls in an application.
open class CallKitService: NSObject, CXProviderDelegate, @unchecked Sendable {

    @Injected(\.callCache) private var callCache
    @Injected(\.uuidFactory) private var uuidFactory

    /// Represents a call that is being managed by the service.
    final class CallEntry: Equatable, @unchecked Sendable {
        var call: Call
        var callUUID: UUID
        var createdBy: User?
        var isActive: Bool = false

        init(
            call: Call,
            callUUID: UUID = .init()
        ) {
            self.call = call
            self.callUUID = callUUID
        }

        static func == (
            lhs: CallKitService.CallEntry,
            rhs: CallKitService.CallEntry
        ) -> Bool {
            lhs.call.cId == rhs.call.cId
                && lhs.callUUID == rhs.callUUID
        }
    }

    /// The currently active StreamVideo client.
    /// - Important: We need to update it whenever a user logins.
    public var streamVideo: StreamVideo? {
        didSet { didUpdate(streamVideo) }
    }

    /// The unique identifier for the call.
    open var callId: String {
        if let active, let callEntry = callEntry(for: active) {
            return callEntry.call.callId
        } else {
            return ""
        }
    }

    /// The type of call.
    open var callType: String {
        if let active, let callEntry = callEntry(for: active) {
            return callEntry.call.callType
        } else {
            return ""
        }
    }

    /// The icon data for the call template.
    open var iconTemplateImageData: Data?
    /// The ringtone sound to use for CallKit ringing calls.
    open var ringtoneSound: String?
    /// Whether the call can be held on its own or swapped with another call.
    /// - Important: Holding a call isn't supported yet!
    open var supportsHolding: Bool = false
    /// Whether the service supports Video in addition to Audio calls. If set to true, CallKit push notification
    /// title, will be suffixed with the word `Video` next to the application's name. Otherwise, it will be
    /// suffixed with the word `Audio`.
    /// - Note: defaults to `false`.
    open var supportsVideo: Bool = false

    var callSettings: CallSettings?

    /// The call controller used for managing calls.
    open internal(set) lazy var callController = CXCallController()
    /// The call provider responsible for handling call-related actions.
    open internal(set) lazy var callProvider = buildProvider()

    private var _storage: [UUID: CallEntry] = [:]
    private let storageAccessQueue: UnfairQueue = .init()
    private var active: UUID?
    var callCount: Int { storageAccessQueue.sync { _storage.count } }

    private var callEventsSubscription: Task<Void, Error>?
    private var callEndedNotificationCancellable: AnyCancellable?
    private var ringingTimerCancellable: AnyCancellable?

    /// Initializes the `CallKitService` instance.
    override public init() {
        super.init()

        // Subscribe to the call ended notification.
        callEndedNotificationCancellable = NotificationCenter
            .default
            .publisher(for: Notification.Name(CallNotification.callEnded))
            .compactMap { $0.object as? Call }
            .sink { [weak self] in self?.callEnded($0.cId) }
    }

    /// Reports an incoming call to the CallKit framework.
    ///
    /// - Parameters:
    ///   - cid: The call ID.
    ///   - localizedCallerName: The localized caller name.
    ///   - callerId: The caller's identifier.
    ///   - hasVideo: Indicator if call is video or audio. If nil we default to the value of `supportsVideo`
    ///   - completion: A closure to be called upon completion.
    @MainActor
    open func reportIncomingCall(
        _ cid: String,
        localizedCallerName: String,
        callerId: String,
        hasVideo: Bool? = nil,
        completion: @escaping (Error?) -> Void
    ) {
        let hasVideo = hasVideo ?? supportsVideo
        let (callUUID, callUpdate) = buildCallUpdate(
            cid: cid,
            localizedCallerName: localizedCallerName,
            callerId: callerId,
            hasVideo: hasVideo
        )

        callProvider.reportNewIncomingCall(
            with: callUUID,
            update: callUpdate,
            completion: completion
        )

        log.debug(
            """
            Reporting VoIP incoming call with
            callUUID:\(callUUID) 
            cid:\(cid)
            callerId:\(callerId)
            callerName:\(localizedCallerName)
            hasVideo: \(hasVideo)
            """
        )

        guard let streamVideo, let callEntry = callEntry(for: callUUID) else {
            log.warning(
                """
                CallKit operation:reportIncomingCall cannot be fulfilled because 
                StreamVideo is nil.
                """
            )
            callEnded(cid)
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

                if streamVideo.state.ringingCall?.cId != callEntry.call.cId {
                    Task { @MainActor in
                        streamVideo.state.ringingCall = callEntry.call
                    }
                }

                let callState = try await callEntry.call.get()
                if !checkIfCallWasHandled(callState: callState) {
                    callEntry.createdBy = callState.call.createdBy.toUser
                    setUpRingingTimer(for: callState)
                } else {
                    log.debug(
                        """
                        Rejecting VoIP incoming call as it has been handled.
                        callUUID:\(callUUID)
                        cid:\(cid) 
                        callerId:\(callerId)
                        callerName:\(localizedCallerName)
                        """
                    )
                    callEnded(cid)
                }
            } catch {
                log.error(
                    """
                    Failed to report incoming call with 
                    callId:\(callId)
                    callType:\(callType)
                    """
                )
                callEnded(cid)
            }
        }
    }

    /// Handles the event when a call is accepted.
    ///
    /// - Parameter response: The call accepted event.
    open func callAccepted(_ response: CallAcceptedEvent) {
        /// The call was accepted somewhere else (e.g the incoming call on the same device or another
        /// device). No action is required.
        guard
            let newCallEntry = callEntry(for: response.callCid),
            newCallEntry.callUUID != active // Ensure that the new call isn't the currently active one.
        else {
            return
        }
        callProvider.reportCall(
            with: newCallEntry.callUUID,
            endedAt: nil,
            reason: .answeredElsewhere
        )
        ringingTimerCancellable?.cancel()
        ringingTimerCancellable = nil
        set(nil, for: newCallEntry.callUUID)
        callCache.remove(for: newCallEntry.call.cId)
    }

    /// Handles the event when a call is rejected.
    ///
    /// - Parameter response: The call rejected event.
    open func callRejected(_ response: CallRejectedEvent) {
        guard
            let newCallEntry = callEntry(for: response.callCid),
            newCallEntry.callUUID != active // Ensure that the new call isn't the currently active one.
        else {
            return
        }

        let isCurrentUserRejection = response.user.id == streamVideo?.user.id
        let isCallCreatorRejection = response.user.id == newCallEntry.createdBy?.id

        guard
            (isCurrentUserRejection || isCallCreatorRejection)
        else {
            return
        }
        callProvider.reportCall(
            with: newCallEntry.callUUID,
            endedAt: nil,
            reason: .declinedElsewhere
        )
        ringingTimerCancellable?.cancel()
        ringingTimerCancellable = nil
        set(nil, for: newCallEntry.callUUID)
        callCache.remove(for: newCallEntry.call.cId)
    }

    /// Handles the event when a call ends.
    open func callEnded(_ cId: String) {
        guard let callEndedEntry = callEntry(for: cId) else {
            return
        }
        Task {
            do {
                // End the call.
                try await requestTransaction(
                    CXEndCallAction(
                        call: callEndedEntry.callUUID
                    )
                )
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
            if let call = callEntry(for: response.callCid)?.call,
               call.state.participants.count == 1 {
                callEnded(response.callCid)
            }
        }
    }

    // MARK: - CXProviderDelegate

    /// Called when the provider has been reset. Delegates must respond to this callback by cleaning up
    /// all internal call state (disconnecting communication channels, releasing network resources, etc.).
    /// This callback can be treated as a request to end all calls without the need to respond to any actions
    open func providerDidReset(_ provider: CXProvider) {
        log.debug("CXProvider didReset.")
        storageAccessQueue.sync {
            for (_, entry) in _storage {
                entry.call.leave()
            }
        }
    }

    open func provider(
        _ provider: CXProvider,
        didActivate audioSession: AVAudioSession
    ) {
        log.debug("AudioSession is now active with router:\(audioSession.currentRoute).")
    }

    public func provider(
        _ provider: CXProvider,
        didDeactivate audioSession: AVAudioSession
    ) {
        log.debug("AudioSession is now inactive with router:\(audioSession.currentRoute).")
    }

    open func provider(
        _ provider: CXProvider,
        perform action: CXAnswerCallAction
    ) {
        guard
            action.callUUID != active,
            let callToJoinEntry = callEntry(for: action.callUUID)
        else {
            return action.fail()
        }

        ringingTimerCancellable?.cancel()
        ringingTimerCancellable = nil
        active = action.callUUID

        Task { @MainActor in
            log
                .debug(
                    "Answering VoIP incoming call with callId:\(callToJoinEntry.call.callId) callType:\(callToJoinEntry.call.callType) callerId:\(String(describing: callToJoinEntry.createdBy?.id))."
                )

            do {
                try await callToJoinEntry.call.accept()
            } catch {
                log.error(error)
            }

            do {
                try await callToJoinEntry.call.join(callSettings: callSettings)
                action.fulfill()
            } catch {
                callToJoinEntry.call.leave()
                set(nil, for: action.callUUID)
                log.error(error)
                action.fail()
            }

            let callSettings = callToJoinEntry.call.state.callSettings
            do {
                if callSettings.audioOn == false {
                    try await requestTransaction(
                        CXSetMutedCallAction(
                            call: callToJoinEntry.callUUID,
                            muted: true
                        )
                    )
                }
            } catch {
                log.error(
                    """
                    While joining call id:\(callToJoinEntry.call.cId) we failed to mute the microphone.
                    \(callSettings)
                    """,
                    error: error
                )
            }
        }
    }

    open func provider(
        _ provider: CXProvider,
        perform action: CXEndCallAction
    ) {
        ringingTimerCancellable?.cancel()
        ringingTimerCancellable = nil
        let currentCallWasEnded = action.callUUID == active

        guard let stackEntry = callEntry(for: action.callUUID) else {
            action.fail()
            return
        }

        Task {
            log.debug(
                """
                Ending VoIP call with
                callId:\(stackEntry.call.callId)
                callType:\(stackEntry.call.callType)
                callerId:\(String(describing: stackEntry.createdBy?.id))
                """
            )
            do {
                let rejectionReason = streamVideo?
                    .rejectionReasonProvider
                    .reason(
                        for: stackEntry.call.cId,
                        ringTimeout: false
                    )
                log.debug(
                    """
                    Rejecting with reason: \(rejectionReason ?? "nil")
                    call:\(stackEntry.call.callId)
                    callType: \(stackEntry.call.callType)
                    """
                )
                try await stackEntry.call.reject(reason: rejectionReason)
            } catch {
                log.error(error)
            }
            if currentCallWasEnded {
                stackEntry.call.leave()
            }
            set(nil, for: action.callUUID)
            action.fulfill()
        }
    }

    open func provider(
        _ provider: CXProvider,
        perform action: CXSetMutedCallAction
    ) {
        guard let stackEntry = callEntry(for: action.callUUID) else {
            action.fail()
            return
        }
        Task {
            do {
                if action.isMuted {
                    try await stackEntry.call.microphone.disable()
                } else {
                    try await stackEntry.call.microphone.enable()
                }
            } catch {
                log.error(
                    "Unable to perform muteCallAction isMuted:\(action.isMuted).",
                    error: error
                )
            }
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
        let timeout = TimeInterval(callState.call.settings.ring.autoCancelTimeoutMs / 1000)
        ringingTimerCancellable = Foundation.Timer.publish(
            every: timeout,
            on: .main,
            in: .default
        )
        .autoconnect()
        .sink { [weak self] _ in
            log.debug("Detected ringing timeout, hanging up...")
            self?.callEnded(callState.call.cid)
            self?.ringingTimerCancellable = nil
        }
    }

    /// A method that's being called every time the StreamVideo instance is getting updated.
    /// - Parameter streamVideo: The new StreamVideo instance (nil if none)
    open func didUpdate(_ streamVideo: StreamVideo?) {
        subscribeToCallEvents()
    }

    // MARK: - Private helpers

    /// Subscription to event should **never** perform an accept or joining a call action. Those actions
    /// are only being performed explicitly from the component that receives the user action.
    /// Subscribing to events is being used to reject/stop calls that have been accepted/rejected
    /// on other devices or components (e.g. incoming callScreen, CallKitService)
    private func subscribeToCallEvents() {
        callEventsSubscription?.cancel()
        callEventsSubscription = nil

        guard let streamVideo else {
            log.warning(
                """
                CallKit operation:\(#function) cannot be fulfilled because
                StreamVideo is nil.
                """
            )
            return
        }

        callEventsSubscription = Task {
            for await event in streamVideo.subscribe() {
                switch event {
                case let .typeCallEndedEvent(response):
                    callEnded(response.callCid)
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

        log.debug("\(type(of: self)) is now subscribed to CallEvent updates.")
    }

    private func buildProvider(
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
        configuration.ringtoneSound = ringtoneSound

        if supportsHolding {
            // Holding a call isn't supported yet.
        } else {
            configuration.maximumCallGroups = 1
            configuration.maximumCallsPerCallGroup = 1
        }

        let provider = CXProvider(configuration: configuration)
        provider.setDelegate(self, queue: nil)
        return provider
    }

    private func buildCallUpdate(
        cid: String,
        localizedCallerName: String,
        callerId: String,
        hasVideo: Bool
    ) -> (UUID, CXCallUpdate) {
        let update = CXCallUpdate()
        let idComponents = cid.components(separatedBy: ":")
        let uuid = uuidFactory.get()
        if
            idComponents.count >= 2,
            let call = streamVideo?.call(
                callType: idComponents[0],
                callId: idComponents[1]
            ) {
            set(.init(call: call, callUUID: uuid), for: uuid)
        }

        update.localizedCallerName = localizedCallerName
        update.remoteHandle = CXHandle(type: .generic, value: callerId)
        update.hasVideo = hasVideo
        update.supportsDTMF = false

        if supportsHolding {
            log.warning("CallKit hold isn't supported.")
        } else {
            update.supportsGrouping = false
            update.supportsHolding = false
            update.supportsUngrouping = false
        }

        return (uuid, update)
    }

    // MARK: - Storage Access

    private func set(_ value: CallEntry?, for key: UUID) {
        storageAccessQueue.sync {
            _storage[key] = value
        }
    }

    private func callEntry(for cId: String) -> CallEntry? {
        storageAccessQueue.sync {
            _storage
                .first { $0.value.call.cId == cId }?
                .value
        }
    }

    private func callEntry(for uuid: UUID) -> CallEntry? {
        storageAccessQueue.sync { _storage[uuid] }
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

extension CXAnswerCallAction: @unchecked Sendable {}
extension CXSetHeldCallAction: @unchecked Sendable {}
extension CXSetMutedCallAction: @unchecked Sendable {}
