//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
import CallKit
import Combine
import Foundation
import StreamWebRTC

/// Manages CallKit integration for VoIP calls.
open class CallKitService: NSObject, CXProviderDelegate, @unchecked Sendable {

    struct MuteRequest: Equatable {
        var callUUID: UUID
        var isMuted: Bool
    }

    @Injected(\.callCache) private var callCache
    @Injected(\.uuidFactory) private var uuidFactory
    @Injected(\.currentDevice) private var currentDevice
    @Injected(\.audioStore) private var audioStore
    @Injected(\.permissions) private var permissions
    @Injected(\.applicationStateAdapter) private var applicationStateAdapter
    private let disposableBag = DisposableBag()

    /// Represents a call that is being managed by the service.
    final class CallEntry: Equatable, @unchecked Sendable {
        var call: Call
        var callUUID: UUID
        var createdBy: User?
        var isActive: Bool = false
        var ringingTimedOut: Bool = false
        var isEndedElsewhere: Bool = false

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

    /// Current `StreamVideo` client. Update when user logs in.
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
    /// Whether video is supported. If true, CallKit push titles add "Video";
    /// otherwise "Audio". Default is `false`.
    open var supportsVideo: Bool = false
    /// Whether calls received will be showing in Recents app.
    open var includesCallsInRecents: Bool = true

    /// Policy for handling calls when mic permission is missing while the app
    /// runs in the background. See `CallKitMissingPermissionPolicy`.
    open var missingPermissionPolicy: CallKitMissingPermissionPolicy = .none

    var callSettings: CallSettings?

    /// The call controller used for managing calls.
    open internal(set) lazy var callController = CXCallController()
    /// The call provider responsible for handling call-related actions.
    open internal(set) lazy var callProvider = buildProvider()

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
        super.init()

        // Subscribe to the call ended notification.
        callEndedNotificationCancellable = NotificationCenter
            .default
            .publisher(for: Notification.Name(CallNotification.callEnded))
            .compactMap { $0.object as? Call }
            .sink { [weak self] in self?.callEnded($0.cId, ringingTimedOut: false) }

        /// - Important:
        /// It used to debounce System's attempts to mute/unmute the call. It seems that the system
        /// performs rapid mute/unmute attempts when the call is being joined or moving to foreground.
        /// The observation below is in place to guard and normalise those attempts to avoid
        /// - rapid speaker and mic toggles
        /// - unnecessary attempts to mute/unmute the mic
        muteActionCancellable = muteActionSubject
            .removeDuplicates()
            .filter { [weak self] _ in self?.applicationStateAdapter.state != .foreground }
            .debounce(for: 0.5, scheduler: DispatchQueue.global(qos: .userInteractive))
            .sink { [weak self] in self?.performMuteRequest($0) }
    }

    /// Report an incoming call to CallKit.
    open func reportIncomingCall(
        _ cid: String,
        localizedCallerName: String,
        callerId: String,
        hasVideo: Bool = false,
        completion: @Sendable @escaping (Error?) -> Void
    ) {
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
            """,
            subsystems: .callKit
        )

        guard let streamVideo, let callEntry = callEntry(for: callUUID) else {
            log.warning(
                """
                CallKit operation:reportIncomingCall cannot be fulfilled because 
                StreamVideo is nil.
                """,
                subsystems: .callKit
            )
            callEnded(cid, ringingTimedOut: false)
            return
        }

        Task(disposableBag: disposableBag) { [weak self] in
            guard let self else {
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
                    Task(disposableBag: disposableBag) { [weak self] in
                        self?.streamVideo?.state.ringingCall = callEntry.call
                    }
                }

                try missingPermissionPolicy
                    .policy
                    .reportCall()

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
                        """,
                        subsystems: .callKit
                    )
                    callEnded(cid, ringingTimedOut: false)
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
                callEnded(cid, ringingTimedOut: false)
            }
        }
    }

    /// Handle acceptance by the same user on another device.
    open func callAccepted(_ response: CallAcceptedEvent) {
        // Accepted elsewhere.
        /// device). No action is required.
        guard
            let newCallEntry = callEntry(for: response.callCid),
            newCallEntry.callUUID != active, // Ensure that the new call isn't the currently active one.
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

    /// Handle a rejection from the same user or the call creator elsewhere.
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

    /// Handle call end event.
    open func callEnded(
        _ cId: String,
        ringingTimedOut: Bool
    ) {
        guard let callEndedEntry = callEntry(for: cId) else {
            return
        }
        if ringingTimedOut {
            callEndedEntry.ringingTimedOut = ringingTimedOut
        } else {
            callEndedEntry.isEndedElsewhere = true
        }
        set(callEndedEntry, for: callEndedEntry.callUUID)

        log.debug(
            """
            CallEnded
            callId:\(callEndedEntry.call.callId)
            callType:\(callEndedEntry.call.callType)
            callerId:\(callEndedEntry.createdBy?.id)
            ringingTimedOut:\(callEndedEntry.ringingTimedOut)
            isEndedElsewhere:\(callEndedEntry.isEndedElsewhere)
            """,
            subsystems: .callKit
        )
        Task(disposableBag: disposableBag) { [weak self] in
            do {
                // End the call.
                try await self?.requestTransaction(
                    CXEndCallAction(
                        call: callEndedEntry.callUUID
                    )
                )
            } catch {
                log.error(error, subsystems: .callKit)
            }
        }
    }

    /// Handle when a participant leaves the call.
    open func callParticipantLeft(
        _ response: CallSessionParticipantLeftEvent
    ) {
        // End the call if only one participant remains.
        /// in the call, we leave.
        Task(disposableBag: disposableBag) { @MainActor [weak self] in
            guard let self else {
                return
            }
            if let call = callEntry(for: response.callCid)?.call,
               call.state.participants.count == 1 {
                log.debug(
                    "Call will end as only one participant left in the call",
                    subsystems: .callKit
                )
                callEnded(response.callCid, ringingTimedOut: false)
            }
        }
    }

    // MARK: - CXProviderDelegate

    /// Provider reset: end and clean up calls.
    open func providerDidReset(_ provider: CXProvider) {
        log.debug("CXProvider didReset.", subsystems: .callKit)
        storageAccessQueue.sync {
            for (_, entry) in _storage {
                entry.call.didPerform(.didReset)
                entry.call.leave()
            }
        }
    }

    open func provider(
        _ provider: CXProvider,
        didActivate audioSession: AVAudioSession
    ) {
        log.debug(
            """
            CallKit audioSession was activated:
                category: \(audioSession.category)
                mode: \(audioSession.mode)
                options: \(audioSession.categoryOptions)
                route: \(audioSession.currentRoute)
            
            CallSettings: \(callSettings)
            """,
            subsystems: .callKit
        )

        /// Ask the audio store to activate the CallKit session.
        ///
        ///
        /// of the audio session during a call.
        audioStore.dispatch(.callKit(.activate(audioSession)))

        observeCallSettings(active)
    }

    public func provider(
        _ provider: CXProvider,
        didDeactivate audioSession: AVAudioSession
    ) {
        log.debug(
            """
            CallKit audioSession was deactivated:
                category: \(audioSession.category)
                mode: \(audioSession.mode)
                options: \(audioSession.categoryOptions)
                route: \(audioSession.currentRoute)
            
            CallSettings: \(callSettings)
            """,
            subsystems: .callKit
        )

        /// Ask the audio store to deactivate the CallKit session.
        ///
        ///
        audioStore.dispatch(.callKit(.deactivate(audioSession)))
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
        callToJoinEntry.call.didPerform(.performAnswerCall)

        Task(disposableBag: disposableBag) { @MainActor [weak self] in
            guard let self else {
                return
            }
            log
                .debug(
                    "Answering VoIP incoming call with callId:\(callToJoinEntry.call.callId) callType:\(callToJoinEntry.call.callType) callerId:\(callToJoinEntry.createdBy?.id)."
                )

            do {
                try await callToJoinEntry.call.accept()
            } catch {
                log.error(error, subsystems: .callKit)
            }

            do {
                /// Mark join source as `.callKit` for audio session.
                ///
                callToJoinEntry.call.state.joinSource = .callKit

                try await callToJoinEntry.call.join(callSettings: callSettings)
                action.fulfill()
            } catch {
                callToJoinEntry.call.leave()
                set(nil, for: action.callUUID)
                log.error(error, subsystems: .callKit)
                action.fail()
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
        let actionCallUUID = action.callUUID

        Task(disposableBag: disposableBag) { [weak self] in
            guard let self else {
                return
            }
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
                stackEntry.call.didPerform(.performEndCall)
                stackEntry.call.leave()
            } else {
                do {
                    let rejectionReason = await streamVideo?
                        .rejectionReasonProvider
                        .reason(
                            for: stackEntry.call.cId,
                            ringTimeout: stackEntry.ringingTimedOut
                        )
                    log.debug(
                        """
                        Rejecting with reason: \(rejectionReason ?? "nil")
                        call:\(stackEntry.call.callId)
                        callType: \(stackEntry.call.callType)
                        """,
                        subsystems: .callKit
                    )
                    stackEntry.call.didPerform(.performRejectCall)
                    try await stackEntry.call.reject(reason: rejectionReason)
                } catch {
                    log.error(error, subsystems: .callKit)
                }
            }
            set(nil, for: actionCallUUID)
        }

        action.fulfill()
    }

    open func provider(
        _ provider: CXProvider,
        perform action: CXSetMutedCallAction
    ) {
        guard
            let stackEntry = callEntry(for: action.callUUID)
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

    // MARK: - Helpers

    /// Request a CallKit transaction.
    open func requestTransaction(
        _ action: CXAction
    ) async throws {
        try await callController.requestTransaction(with: action)
    }

    /// Return whether this call was already accepted or rejected.
    open func checkIfCallWasHandled(callState: GetCallResponse) -> Bool {
        guard let streamVideo else {
            log.warning(
                "CallKit operation:\(#function) cannot be fulfilled because StreamVideo is nil.",
                subsystems: .callKit
            )
            return false
        }

        var allMembers = callState.members.map(\.user.toUser)
        let creator = callState.call.createdBy.toUser
        let isUserInMembersArray = allMembers.filter { $0.id == creator.id }.isEmpty == false
        if !isUserInMembersArray {
            allMembers.append(creator)
        }
        let allCallees = allMembers.filter { $0.id != creator.id }

        let currentUserId = streamVideo.user.id
        let acceptedBy = callState.call.session?.acceptedBy ?? [:]
        let rejectedBy = callState.call.session?.rejectedBy ?? [:]
        let isAccepted = acceptedBy[currentUserId] != nil
        let isRejected = rejectedBy[currentUserId] != nil
        let isRejectedByEveryoneElse = (allCallees.endIndex > 1)
            && rejectedBy.keys.filter { $0 != currentUserId }.count == (allCallees.endIndex - 1)
        return isAccepted || isRejected || isRejectedByEveryoneElse
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

    /// Called when `StreamVideo` changes. Adds/removes the audio reducer and
    /// subscribes to events on real devices.
    open func didUpdate(_ streamVideo: StreamVideo?) {
        guard currentDevice.deviceType != .simulator else {
            return
        }

        subscribeToCallEvents()
    }

    // MARK: - Private helpers

    /// Do not auto-accept or join in subscriptions. Mirror remote accept/
    /// reject/end to keep state in sync.
    private func subscribeToCallEvents() {
        disposableBag.removeAll()

        guard let streamVideo else {
            log.warning(
                """
                CallKit operation:\(#function) cannot be fulfilled because
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
                    callEnded(response.callCid, ringingTimedOut: false)
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
        configuration.includesCallsInRecents = includesCallsInRecents

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
            log.warning(
                "CallKit hold isn't supported.",
                subsystems: .callKit
            )
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

    private func observeCallSettings(
        _ callUUID: UUID?
    ) {
        let key = "call-settings-observation"
        guard
            let callUUID,
            let callEntry = callEntry(for: callUUID)
        else {
            disposableBag.remove(key)
            return
        }

        Task { @MainActor in
            callEntry
                .call
                .state
                .$callSettings
                .map { $0.audioOn == false }
                .removeDuplicates()
                .log(.debug, subsystems: .callKit) { "Will perform SetMutedCallAction with muted:\($0). " }
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
                try await requestTransaction(CXSetMutedCallAction(call: callUUID, muted: muted))
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
}

extension CallKitService: InjectionKey {
    /// Current `CallKitService` instance.
    public nonisolated(unsafe) static var currentValue: CallKitService = .init()
}

extension InjectedValues {
    /// Accessor for `CallKitService`.
    public var callKitService: CallKitService {
        get { Self[CallKitService.self] }
        set { Self[CallKitService.self] = newValue }
    }
}
