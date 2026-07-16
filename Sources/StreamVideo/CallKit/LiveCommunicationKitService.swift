//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

#if canImport(LiveCommunicationKit)
import AVFoundation
import Combine
import Foundation
import LiveCommunicationKit
import StreamWebRTC

/// Manages LiveCommunicationKit integration for VoIP calls on iOS 27 and newer.
@available(iOS 27.0, *)
open class LiveCommunicationKitService: NSObject, ConversationManagerDelegate, SystemCallingService, @unchecked Sendable {

    struct MuteRequest: Equatable {
        var callUUID: UUID
        var isMuted: Bool
    }

    /// LiveCommunicationKit actions are completed asynchronously by design,
    /// but the action classes don't currently declare `Sendable`.
    /// This wrapper keeps the non-Sendable reference private and only forwards
    /// one-shot completion calls from the join flow.
    private final class SendableJoinConversationAction: @unchecked Sendable {
        private let action: JoinConversationAction

        init(_ action: JoinConversationAction) {
            self.action = action
        }

        var conversationUUID: UUID { action.conversationUUID }

        func fail() {
            action.fail()
        }

        func fulfill(dateConnected: Date) {
            action.fulfill(dateConnected: dateConnected)
        }
    }

    @Injected(\.callCache) private var callCache
    @Injected(\.uuidFactory) private var uuidFactory
    @Injected(\.currentDevice) private var currentDevice
    @Injected(\.audioStore) private var audioStore
    @Injected(\.permissions) private var permissions
    @Injected(\.applicationStateAdapter) private var applicationStateAdapter
    @Injected(\.callKitService) private var callKitService
    private let disposableBag = DisposableBag()

    /// Represents a call that is being managed by the service.
    final class CallEntry: Equatable, @unchecked Sendable {
        var call: Call
        var callUUID: UUID
        var createdBy: User?
        var isActive: Bool = false
        var ringingTimedOut: Bool = false
        var isEndedElsewhere: Bool = false
        var leaveReason: String?

        init(
            call: Call,
            callUUID: UUID = .init()
        ) {
            self.call = call
            self.callUUID = callUUID
        }

        static func == (
            lhs: LiveCommunicationKitService.CallEntry,
            rhs: LiveCommunicationKitService.CallEntry
        ) -> Bool {
            lhs.call.cId == rhs.call.cId
                && lhs.callUUID == rhs.callUUID
        }
    }

    /// Current `StreamVideo` client. Update when user logs in.
    public var streamVideo: StreamVideo? {
        didSet { didUpdate(streamVideo) }
    }

    /// Stores the latest system-calling lifecycle event.
    let eventPipelineSubject: CurrentValueSubject<CallKitService.Event, Never>

    /// Publishes lifecycle events that temporarily drive UI state while the SDK
    /// restores its regular call state.
    public let eventPipeline: AnyPublisher<CallKitService.Event, Never>

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
    /// The ringtone sound to use for ringing calls.
    open var ringtoneSound: String?
    /// Whether the call can be held on its own or swapped with another call.
    /// - Important: Holding a call isn't supported yet!
    open var supportsHolding: Bool = false
    /// Whether video is supported.
    open var supportsVideo: Bool = false
    /// Whether calls received will be showing in Recents app.
    open var includesCallsInRecents: Bool = true

    /// Policy for handling calls when mic permission is missing while the app
    /// runs in the background. See `CallKitMissingPermissionPolicy`.
    open var missingPermissionPolicy: CallKitMissingPermissionPolicy = .none

    /// The policy that decides whether managed calls should leave automatically
    /// when participant state changes.
    open var participantAutoLeavePolicy: ParticipantAutoLeavePolicy = LastParticipantAutoLeavePolicy() {
        didSet {
            var oldValue = oldValue
            oldValue.onPolicyTriggered = nil
            participantAutoLeavePolicy.onPolicyTriggered = { [weak self] in
                self?.participantAutoLeavePolicyTriggered()
            }
        }
    }

    /// Optional interceptor invoked after the call join response has been
    /// applied locally but before the SDK treats the call as fully entered.
    public var callJoinInterceptor: CallJoinIntercepting?

    var callSettings: CallSettings?

    /// The conversation manager used for LiveCommunicationKit actions.
    open internal(set) lazy var conversationManager = buildConversationManager()

    private var _storage: [UUID: CallEntry] = [:]
    private let storageAccessQueue: UnfairQueue = .init()
    private var active: UUID?

    var callCount: Int { storageAccessQueue.sync { _storage.count } }

    private var callEndedNotificationCancellable: AnyCancellable?
    private var ringingTimerCancellable: AnyCancellable?

    private let muteActionSubject = PassthroughSubject<MuteRequest, Never>()
    private var muteActionCancellable: AnyCancellable?
    private let muteProcessingQueue = OperationQueue(maxConcurrentOperationCount: 1)
    private var isMuted: Bool?

    /// Initialize.
    override public init() {
        let eventPipelineSubject = CurrentValueSubject<CallKitService.Event, Never>(.idle)
        self.eventPipelineSubject = eventPipelineSubject
        self.eventPipeline = eventPipelineSubject.eraseToAnyPublisher()

        super.init()

        callEndedNotificationCancellable = NotificationCenter
            .default
            .publisher(for: Notification.Name(CallNotification.callEnded))
            .compactMap { $0.object as? Call }
            .sink {
                [weak self] in self?.callEnded(
                    $0.cId,
                    ringingTimedOut: false,
                    leaveReason: StreamRejectionReasonProvider
                        .HandledCallReason
                        .callEndedLocally
                        .rawValue
                )
            }

        muteActionCancellable = muteActionSubject
            .removeDuplicates()
            .filter { [weak self] _ in self?.applicationStateAdapter.state != .foreground }
            .debounce(for: 0.5, scheduler: DispatchQueue.global(qos: .userInteractive))
            .sink { [weak self] in self?.performMuteRequest($0) }

        participantAutoLeavePolicy.onPolicyTriggered = { [weak self] in
            self?.participantAutoLeavePolicyTriggered()
        }
    }

    /// Report an incoming call to LiveCommunicationKit.
    open func reportIncomingCall(
        _ cid: String,
        localizedCallerName: String,
        callerId: String,
        hasVideo: Bool = false,
        completion: @Sendable @escaping (Error?) -> Void
    ) {
        let (callUUID, update) = buildConversationUpdate(
            cid: cid,
            localizedCallerName: localizedCallerName,
            callerId: callerId,
            hasVideo: hasVideo
        )

        log.debug(
            """
            Reporting LiveCommunicationKit incoming call with
            callUUID:\(callUUID)
            cid:\(cid)
            callerId:\(callerId)
            callerName:\(localizedCallerName)
            hasVideo: \(hasVideo)
            """,
            subsystems: .callKit
        )

        Task(disposableBag: disposableBag) { [weak self] in
            guard let self else {
                return
            }

            do {
                try await conversationManager.reportNewIncomingConversation(
                    uuid: callUUID,
                    update: update
                )
                completion(nil)
            } catch {
                completion(error)
                log.error(
                    """
                    Failed to report LiveCommunicationKit incoming call with
                    cid: \(cid)
                    localizedCallerName: \(localizedCallerName)
                    hasVideo: \(hasVideo)
                    """,
                    subsystems: .callKit,
                    error: error
                )
                set(nil, for: callUUID)
                return
            }

            await prepareIncomingCall(
                callUUID: callUUID,
                cid: cid,
                localizedCallerName: localizedCallerName,
                callerId: callerId,
                hasVideo: hasVideo
            )
        }
    }

    /// Handle acceptance by the same user on another device.
    open func callAccepted(_ response: CallAcceptedEvent) {
        guard
            let newCallEntry = callEntry(for: response.callCid),
            newCallEntry.callUUID != active,
            response.user.id == streamVideo?.user.id
        else {
            return
        }
        log.debug(
            """
            Call accepted
            callId:\(newCallEntry.call.callId)
            callType:\(newCallEntry.call.callType)
            callerId:\(newCallEntry.createdBy?.id)
            ringingTimedOut:\(newCallEntry.ringingTimedOut)
            isEndedElsewhere:\(newCallEntry.isEndedElsewhere)
            """,
            subsystems: .callKit
        )

        reportConversationEnded(for: newCallEntry, reason: .joinedElsewhere)
        ringingTimerCancellable?.cancel()
        ringingTimerCancellable = nil
        set(nil, for: newCallEntry.callUUID)
        callCache.remove(for: newCallEntry.call.cId)
    }

    /// Handle a rejection from the same user or the call creator elsewhere.
    open func callRejected(_ response: CallRejectedEvent) {
        guard
            let newCallEntry = callEntry(for: response.callCid),
            newCallEntry.callUUID != active
        else {
            return
        }

        let isCurrentUserRejection = response.user.id == streamVideo?.user.id
        let isCallCreatorRejection = response.user.id == newCallEntry.createdBy?.id

        guard isCurrentUserRejection || isCallCreatorRejection else {
            return
        }
        log.debug(
            """
            Call rejected
            callId:\(newCallEntry.call.callId)
            callType:\(newCallEntry.call.callType)
            callerId:\(newCallEntry.createdBy?.id)
            ringingTimedOut:\(newCallEntry.ringingTimedOut)
            isEndedElsewhere:\(newCallEntry.isEndedElsewhere)
            isCurrentUserRejection:\(isCurrentUserRejection)
            isCallCreatorRejection:\(isCallCreatorRejection)
            """,
            subsystems: .callKit
        )

        reportConversationEnded(for: newCallEntry, reason: .declinedElsewhere)
        ringingTimerCancellable?.cancel()
        ringingTimerCancellable = nil
        set(nil, for: newCallEntry.callUUID)
        callCache.remove(for: newCallEntry.call.cId)
    }

    /// Handles a ringing or active LiveCommunicationKit call ending.
    open func callEnded(
        _ cId: String,
        ringingTimedOut: Bool,
        leaveReason: String? = nil
    ) {
        endCall(
            cId,
            ringingTimedOut: ringingTimedOut,
            leaveReason: leaveReason
        )
    }

    /// Called when a participant leaves the call.
    open func callParticipantLeft(
        _ response: CallSessionParticipantLeftEvent
    ) {
        _ = response
    }

    // MARK: - ConversationManagerDelegate

    open func conversationManagerDidBegin(_ manager: ConversationManager) {
        log.debug("LiveCommunicationKit ConversationManager didBegin.", subsystems: .callKit)
    }

    open func conversationManagerDidReset(_ manager: ConversationManager) {
        log.debug("LiveCommunicationKit ConversationManager didReset.", subsystems: .callKit)
        storageAccessQueue.sync {
            for (_, entry) in _storage {
                entry.call.didPerform(.didReset)
                entry.call.leave()
            }
        }
        sendEvent(.idle)
    }

    open func conversationManager(
        _ manager: ConversationManager,
        conversationChanged conversation: Conversation
    ) {
        log.debug(
            "LiveCommunicationKit conversation changed uuid:\(conversation.uuid).",
            subsystems: .callKit
        )
    }

    open func conversationManager(
        _ manager: ConversationManager,
        didActivate audioSession: AVAudioSession
    ) {
        log.debug(
            """
            LiveCommunicationKit audioSession was activated:
                category: \(audioSession.category)
                mode: \(audioSession.mode)
                options: \(audioSession.categoryOptions)
                route: \(audioSession.currentRoute)

            CallSettings: \(callSettings)
            """,
            subsystems: .callKit
        )

        audioStore.dispatch(.callKit(.activate(audioSession)))
        observeCallSettings(active)
    }

    public func conversationManager(
        _ manager: ConversationManager,
        didDeactivate audioSession: AVAudioSession
    ) {
        log.debug(
            """
            LiveCommunicationKit audioSession was deactivated:
                category: \(audioSession.category)
                mode: \(audioSession.mode)
                options: \(audioSession.categoryOptions)
                route: \(audioSession.currentRoute)

            CallSettings: \(callSettings)
            """,
            subsystems: .callKit
        )

        audioStore.dispatch(.callKit(.deactivate(audioSession)))
    }

    open func conversationManager(
        _ manager: ConversationManager,
        perform action: ConversationAction
    ) {
        switch action {
        case let action as JoinConversationAction:
            performJoinConversationAction(action)
        case let action as EndConversationAction:
            performEndConversationAction(action)
        case let action as MuteConversationAction:
            performMuteConversationAction(action)
        default:
            log.warning(
                "Unsupported LiveCommunicationKit action:\(action).",
                subsystems: .callKit
            )
            action.fail()
        }
    }

    open func conversationManager(
        _ manager: ConversationManager,
        timedOutPerforming action: ConversationAction
    ) {
        guard
            let joinAction = action as? JoinConversationAction,
            let callToJoinEntry = callEntry(for: joinAction.conversationUUID)
        else {
            log.warning(
                "LiveCommunicationKit timed out performing action:\(action).",
                subsystems: .callKit
            )
            return
        }

        log.warning(
            """
            LiveCommunicationKit timed out performing the join action while joining
            callId:\(callToJoinEntry.call.callId)
            callType:\(callToJoinEntry.call.callType)
            callerId:\(callToJoinEntry.createdBy?.id)
            """,
            subsystems: .callKit
        )

        callToJoinEntry.call.leave(reason: "callkit.join.timeout")
        set(nil, for: joinAction.conversationUUID)
        sendEvent(.idle)
    }

    // MARK: - Helpers

    /// Request a LiveCommunicationKit action.
    open func requestTransaction(
        _ action: ConversationAction
    ) async throws {
        try await conversationManager.perform([action])
    }

    /// Checks whether the incoming ringing call was already handled before
    /// this device finished presenting LiveCommunicationKit.
    open func checkIfCallWasHandled(callState: GetCallResponse) -> String? {
        guard let streamVideo else {
            log.warning(
                "LiveCommunicationKit operation:\(#function) cannot be fulfilled because StreamVideo is nil.",
                subsystems: .callKit
            )
            return StreamRejectionReasonProvider
                .HandledCallReason
                .notConfigured
                .rawValue
        }

        return streamVideo
            .rejectionReasonProvider
            .reason(callState: callState)
    }

    /// Start the ringing timeout timer for the call.
    open func setUpRingingTimer(for callState: GetCallResponse) {
        let timeout = TimeInterval(callState.call.settings.ring.autoCancelTimeoutMs / 1000)
        ringingTimerCancellable = DefaultTimer
            .publish(every: timeout)
            .sink { [weak self] _ in
                log.debug(
                    "Detected ringing timeout, hanging up...",
                    subsystems: .callKit
                )
                self?.callEnded(callState.call.cid, ringingTimedOut: true)
                self?.ringingTimerCancellable = nil
            }
    }

    /// Called when `StreamVideo` changes. Subscribes to events on real devices.
    open func didUpdate(_ streamVideo: StreamVideo?) {
        guard currentDevice.deviceType != .simulator else {
            return
        }

        subscribeToCallEvents()
    }

    // MARK: - Private helpers

    private func prepareIncomingCall(
        callUUID: UUID,
        cid: String,
        localizedCallerName: String,
        callerId: String,
        hasVideo: Bool
    ) async {
        guard let streamVideo, let callEntry = callEntry(for: callUUID) else {
            log.warning(
                """
                LiveCommunicationKit operation:reportIncomingCall cannot be fulfilled because
                StreamVideo is nil.
                """,
                subsystems: .callKit
            )
            callEnded(
                cid,
                ringingTimedOut: false,
                leaveReason: StreamRejectionReasonProvider
                    .HandledCallReason
                    .notConfigured
                    .rawValue
            )
            return
        }

        do {
            if streamVideo.state.connection != .connected {
                let result = await Task(disposableBag: disposableBag) { [weak self] in
                    try await self?.streamVideo?.connect()
                }.result

                switch result {
                case .success:
                    break
                case let .failure(failure):
                    throw failure
                }
            }

            if streamVideo.state.ringingCall?.cId != callEntry.call.cId {
                Task(disposableBag: disposableBag) { @MainActor [weak self] in
                    self?.streamVideo?.state.ringingCall = callEntry.call
                }
            }

            try missingPermissionPolicy
                .policy
                .reportCall()

            let callState = try await callEntry.call.get()
            if let leaveReason = checkIfCallWasHandled(callState: callState) {
                log.debug(
                    "Ending call with reason:\(leaveReason) { uuid:\(callUUID), cid:\(cid), callerId:\(callerId), callerName:\(localizedCallerName) }",
                    subsystems: .callKit
                )
                callEnded(
                    cid,
                    ringingTimedOut: false,
                    leaveReason: leaveReason
                )
            } else {
                callEntry.createdBy = callState.call.createdBy.toUser
                setUpRingingTimer(for: callState)
            }
        } catch {
            log.error(
                """
                Failed to report incoming call with
                cid: \(cid)
                localizedCallerName: \(localizedCallerName)
                hasVideo: \(hasVideo)
                """,
                subsystems: .callKit,
                error: error
            )
            callEnded(
                cid,
                ringingTimedOut: false,
                leaveReason: StreamRejectionReasonProvider
                    .HandledCallReason
                    .reportCallFailed
                    .rawValue
            )
        }
    }

    private func performJoinConversationAction(
        _ action: JoinConversationAction
    ) {
        guard
            action.conversationUUID != active,
            let callToJoinEntry = callEntry(for: action.conversationUUID)
        else {
            return action.fail()
        }

        let conversationUUID = action.conversationUUID
        let action = SendableJoinConversationAction(action)

        ringingTimerCancellable?.cancel()
        ringingTimerCancellable = nil
        active = conversationUUID
        callToJoinEntry.call.didPerform(.performAnswerCall)

        let hasCompletedAction = Atomic(wrappedValue: false)
        @discardableResult @Sendable func completeActionOnce(
            _ completion: @escaping () -> Void
        ) -> Bool {
            var shouldComplete = false
            hasCompletedAction.mutate { hasCompleted in
                shouldComplete = !hasCompleted
                return true
            }
            guard shouldComplete else {
                return false
            }
            completion()
            return true
        }

        Task(disposableBag: disposableBag) { @MainActor [weak self] in
            guard let self else {
                return
            }
            log.debug(
                "Answering LiveCommunicationKit incoming call with callId:\(callToJoinEntry.call.callId) callType:\(callToJoinEntry.call.callType) callerId:\(callToJoinEntry.createdBy?.id)."
            )

            do {
                sendEvent(.accept)
                reportConversationStartedConnecting(for: callToJoinEntry)
                try await callToJoinEntry.call.accept()
            } catch {
                log.error(error, subsystems: .callKit)
                completeActionOnce { action.fail() }
            }

            do {
                sendEvent(.joining(callToJoinEntry.call))
                callToJoinEntry.call.state.joinSource = .callKit(.init {
                    completeActionOnce { action.fulfill(dateConnected: Date()) }
                })

                try await callToJoinEntry.call.join(
                    callSettings: callSettings,
                    policy: .peerConnectionReadinessAware,
                    joinInterceptor: callJoinInterceptor
                )
                sendEvent(.joined)
                reportConversationConnected(for: callToJoinEntry)
            } catch {
                let didFail = completeActionOnce { action.fail() }
                if !didFail {
                    reportConversationEnded(for: callToJoinEntry, reason: .failed)
                }
                if !(error is CallJoinInterceptionError), !(error is TimeOutError) {
                    callToJoinEntry.call.leave()
                }
                set(nil, for: conversationUUID)
                log.error(error, subsystems: .callKit)
                sendEvent(.idle)
            }
        }
    }

    private func performEndConversationAction(
        _ action: EndConversationAction
    ) {
        ringingTimerCancellable?.cancel()
        ringingTimerCancellable = nil
        let currentCallWasEnded = action.conversationUUID == active

        guard let stackEntry = callEntry(for: action.conversationUUID) else {
            action.fail()
            return
        }
        let actionCallUUID = action.conversationUUID

        Task(disposableBag: disposableBag) { [weak self] in
            guard let self else {
                return
            }
            await performEnd(
                stackEntry,
                currentCallWasEnded: currentCallWasEnded
            )
            set(nil, for: actionCallUUID)
        }

        sendEvent(.idle)
        action.fulfill()
    }

    private func performMuteConversationAction(
        _ action: MuteConversationAction
    ) {
        guard
            let stackEntry = callEntry(for: action.conversationUUID)
        else {
            action.fail()
            return
        }

        guard permissions.hasMicrophonePermission else {
            if action.isMuted {
                action.fulfill()
            } else {
                action.fail()
            }
            return
        }

        muteActionSubject.send(
            .init(
                callUUID: stackEntry.callUUID,
                isMuted: action.isMuted
            )
        )
        action.fulfill()
    }

    private func performEnd(
        _ stackEntry: CallEntry,
        currentCallWasEnded: Bool
    ) async {
        log.debug(
            """
            Ending VoIP call with
            callId:\(stackEntry.call.callId)
            callType:\(stackEntry.call.callType)
            callerId:\(stackEntry.createdBy?.id)
            """,
            subsystems: .callKit
        )
        if currentCallWasEnded {
            sendEvent(.reject)
            stackEntry.call.didPerform(.performEndCall)
            stackEntry.call.leave(reason: stackEntry.leaveReason)
        } else {
            do {
                let rejectionReason = if let leaveReason = stackEntry.leaveReason {
                    leaveReason
                } else {
                    await streamVideo?
                        .rejectionReasonProvider
                        .reason(
                            for: stackEntry.call.cId,
                            ringTimeout: stackEntry.ringingTimedOut
                        )
                }
                log.debug(
                    """
                    Rejecting with reason: \(rejectionReason ?? "nil")
                    call:\(stackEntry.call.callId)
                    callType: \(stackEntry.call.callType)
                    """,
                    subsystems: .callKit
                )
                sendEvent(.reject)
                stackEntry.call.didPerform(.performRejectCall)
                try await stackEntry.call.reject(reason: rejectionReason)
            } catch {
                log.error(error, subsystems: .callKit)
            }
        }
    }

    private func subscribeToCallEvents() {
        disposableBag.removeAll()

        guard let streamVideo else {
            log.warning(
                """
                LiveCommunicationKit operation:\(#function) cannot be fulfilled because
                StreamVideo is nil.
                """,
                subsystems: .callKit
            )
            return
        }

        streamVideo
            .eventPublisher()
            .sink { [weak self] event in
                guard let self else { return }
                switch event {
                case let .typeCallEndedEvent(response):
                    callEnded(
                        response.callCid,
                        ringingTimedOut: false,
                        leaveReason: StreamRejectionReasonProvider
                            .HandledCallReason
                            .callEventReceived
                            .rawValue
                    )
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
            .store(in: disposableBag)

        log.debug(
            "\(type(of: self)) is now subscribed to CallEvent updates.",
            subsystems: .callKit
        )
    }

    private func endCall(
        _ cId: String,
        ringingTimedOut: Bool,
        leaveReason: String? = nil
    ) {
        let result: (CallEntry, Bool)? = storageAccessQueue.sync {
            guard
                let callEndedEntry = _storage.first(where: { $0.value.call.cId == cId })?.value
            else {
                return nil
            }

            let wasAlreadyMarkedEnded = callEndedEntry.leaveReason != nil
                || callEndedEntry.isEndedElsewhere
                || callEndedEntry.ringingTimedOut

            guard wasAlreadyMarkedEnded == false else {
                return (callEndedEntry, false)
            }

            if ringingTimedOut {
                callEndedEntry.ringingTimedOut = true
            } else {
                callEndedEntry.isEndedElsewhere = true
            }

            if let leaveReason {
                callEndedEntry.leaveReason = leaveReason
            }

            _storage[callEndedEntry.callUUID] = callEndedEntry

            return (callEndedEntry, true)
        }

        guard let result else {
            return
        }

        let (callEndedEntry, shouldEnd) = result

        log.debug(
            """
            CallEnded
            callId:\(callEndedEntry.call.callId)
            callType:\(callEndedEntry.call.callType)
            callerId:\(callEndedEntry.createdBy?.id)
            ringingTimedOut:\(callEndedEntry.ringingTimedOut)
            isEndedElsewhere:\(callEndedEntry.isEndedElsewhere)
            leaveReason:\(callEndedEntry.leaveReason ?? "nil")
            """,
            subsystems: .callKit
        )
        guard shouldEnd else {
            return
        }

        Task(disposableBag: disposableBag) { [weak self] in
            guard let self else { return }
            reportConversationEnded(
                for: callEndedEntry,
                reason: conversationEndedReason(for: callEndedEntry)
            )
            await performEnd(
                callEndedEntry,
                currentCallWasEnded: callEndedEntry.callUUID == active
            )
            set(nil, for: callEndedEntry.callUUID)
            sendEvent(.idle)
        }
    }

    private func participantAutoLeavePolicyTriggered() {
        guard
            let active,
            let activeCallEntry = callEntry(for: active)
        else {
            return
        }

        callEnded(
            activeCallEntry.call.cId,
            ringingTimedOut: false,
            leaveReason: StreamRejectionReasonProvider
                .HandledCallReason
                .autoLeave
                .rawValue
        )
    }

    private func buildConversationManager(
        supportedHandleTypes: Set<Handle.Kind> = [.generic]
    ) -> ConversationManager {
        if supportsHolding {
            log.warning(
                "LiveCommunicationKit hold isn't supported.",
                subsystems: .callKit
            )
        }

        let configuration = ConversationManager.Configuration(
            ringtoneName: ringtoneSound,
            iconTemplateImageData: iconTemplateImageData,
            maximumConversationGroups: 1,
            maximumConversationsPerConversationGroup: 1,
            includesConversationInRecents: includesCallsInRecents,
            supportsVideo: supportsVideo,
            supportedHandleTypes: supportedHandleTypes
        )
        let manager = ConversationManager(configuration: configuration)
        manager.delegate = self
        return manager
    }

    private func buildConversationUpdate(
        cid: String,
        localizedCallerName: String,
        callerId: String,
        hasVideo: Bool
    ) -> (UUID, Conversation.Update) {
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

        let remoteHandle = Handle(
            type: .generic,
            value: callerId,
            displayName: localizedCallerName
        )
        let localHandle = streamVideo.map {
            Handle(
                type: .generic,
                value: $0.user.id,
                displayName: $0.user.name
            )
        }
        let capabilities: Conversation.Capabilities? = hasVideo ? .video : nil
        let update = Conversation.Update(
            localMember: localHandle,
            members: [remoteHandle],
            activeRemoteMembers: nil,
            capabilities: capabilities
        )

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

    private func observeCallSettings(
        _ callUUID: UUID?
    ) {
        let key = "livecommunicationkit-call-settings-observation"
        guard
            let callUUID,
            let callEntry = callEntry(for: callUUID)
        else {
            disposableBag.remove(key)
            return
        }

        Task { @MainActor [weak self, callEntry, callUUID] in
            guard let disposableBag = self?.disposableBag else { return }
            callEntry
                .call
                .state
                .$callSettings
                .map { $0.audioOn == false }
                .removeDuplicates()
                .log(.debug, subsystems: .callKit) { "Will perform MuteConversationAction with muted:\($0). " }
                .sink { [weak self] in self?.performCallSettingMuteRequest($0, callUUID: callUUID) }
                .store(in: disposableBag, key: key)
        }
    }

    private func performCallSettingMuteRequest(
        _ muted: Bool,
        callUUID: UUID
    ) {
        muteProcessingQueue.addTaskOperation { [weak self] in
            guard
                let self,
                callUUID == active,
                isMuted != muted
            else {
                return
            }
            do {
                try await requestTransaction(
                    MuteConversationAction(conversationUUID: callUUID, isMuted: muted)
                )
                isMuted = muted
            } catch {
                log.warning("Unable to apply CallSettings.audioOn:\(!muted).", subsystems: .callKit)
            }
        }
    }

    private func performMuteRequest(_ request: MuteRequest) {
        muteProcessingQueue.addTaskOperation { [weak self] in
            guard
                let self,
                request.callUUID == active,
                isMuted != request.isMuted,
                let stackEntry = callEntry(for: request.callUUID)
            else {
                return
            }

            do {
                if request.isMuted {
                    stackEntry.call.didPerform(.performSetMutedCall)
                    try await stackEntry.call.microphone.disable()
                } else {
                    stackEntry.call.didPerform(.performSetMutedCall)
                    try await stackEntry.call.microphone.enable()
                }
                isMuted = request.isMuted
            } catch {
                log.error(
                    "Unable to set call uuid:\(request.callUUID) muted:\(request.isMuted) state.",
                    error: error
                )
            }
        }
    }

    private func conversation(for uuid: UUID) -> Conversation? {
        conversationManager.conversations.first { $0.uuid == uuid }
    }

    private func reportConversationStartedConnecting(for entry: CallEntry) {
        guard let conversation = conversation(for: entry.callUUID) else { return }
        conversationManager.reportConversationEvent(
            .conversationStartedConnecting(Date()),
            for: conversation
        )
    }

    private func reportConversationConnected(for entry: CallEntry) {
        guard let conversation = conversation(for: entry.callUUID) else { return }
        conversationManager.reportConversationEvent(
            .conversationConnected(Date()),
            for: conversation
        )
    }

    private func reportConversationEnded(
        for entry: CallEntry,
        reason: Conversation.EndedReason
    ) {
        guard let conversation = conversation(for: entry.callUUID) else { return }
        conversationManager.reportConversationEvent(
            .conversationEnded(Date(), reason),
            for: conversation
        )
    }

    private func conversationEndedReason(
        for entry: CallEntry
    ) -> Conversation.EndedReason {
        if entry.ringingTimedOut {
            return .unanswered
        }

        switch entry.leaveReason {
        case StreamRejectionReasonProvider.HandledCallReason.reportCallFailed.rawValue,
             StreamRejectionReasonProvider.HandledCallReason.notConfigured.rawValue:
            return .failed
        default:
            return .remoteEnded
        }
    }

    private func sendEvent(_ event: CallKitService.Event) {
        eventPipelineSubject.send(event)
        callKitService.eventPipelineSubject.send(event)
    }
}

@available(iOS 27.0, *)
extension LiveCommunicationKitService: InjectionKey {
    /// Current `LiveCommunicationKitService` instance.
    public nonisolated(unsafe) static var currentValue: LiveCommunicationKitService = .init()
}

extension InjectedValues {
    /// Accessor for `LiveCommunicationKitService`.
    @available(iOS 27.0, *)
    public var liveCommunicationKitService: LiveCommunicationKitService {
        get { Self[LiveCommunicationKitService.self] }
        set { Self[LiveCommunicationKitService.self] = newValue }
    }
}
#endif
