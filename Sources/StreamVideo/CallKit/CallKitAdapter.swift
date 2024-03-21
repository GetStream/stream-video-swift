//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CallKit
import Combine
import Foundation

open class CallKitAdapter: NSObject, CXProviderDelegate, @unchecked Sendable {
    public enum State { case idle, joining, inCall }

    @Injected(\.streamVideo) private var streamVideo

    open var callId: String = ""
    open var callType: String = ""
    open var iconTemplateImageData: Data?

    open private(set) lazy var callController = CXCallController()
    open private(set) lazy var callProvider = buildProvider()

    private var call: Call?
    private var state: State = .idle
    private var callKitId: UUID?
    private var createdBy: User?
    private var ringingTimer: Foundation.Timer?

    private var callEndedNotificationCancellable: AnyCancellable?
    private var ringingTimerCancellable: AnyCancellable?

    override init() {
        super.init()

        callEndedNotificationCancellable = NotificationCenter
            .default
            .publisher(for: Notification.Name(CallNotification.callEnded))
            .sink { [weak self] _ in self?.endCurrentCall() }
    }

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
        log
            .debug(
                "Reporting VoIP incoming call with callKitId:\(callUUID) cid:\(cid) callerId:\(callerId) callerName:\(localizedCallerName)."
            )

        if streamVideo.state.connection != .connected {
            Task { @MainActor in try await streamVideo.connect() }
        }

        callProvider.reportNewIncomingCall(
            with: callUUID,
            update: callUpdate,
            completion: completion
        )

        checkIfCallWasHandled(callId: callId, type: callType)
    }

    open func endCurrentCall() {
        Task {
            guard let callKitId = callKitId else { return }
            log.debug("Ending current VoIP call with callKitId:\(callKitId).")
            let endCallAction = CXEndCallAction(call: callKitId)
            let transaction = CXTransaction(action: endCallAction)
            do {
                try await requestTransaction(transaction)
                self.callKitId = nil
            } catch {
                log.error("Error while executing the transaction", error: error)
            }
        }
    }

    // MARK: - CXProviderDelegate

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

        Task { @MainActor in
            state = .joining
            do {
                log.debug("Answering VoIP incoming call with callId:\(callId) callType:\(callType).")
                call = streamVideo.call(callType: callType, callId: callId)
                try await call?.accept()
                try await call?.join()
                state = .inCall
                action.fulfill()
            } catch {
                call?.leave()
                call = nil
                state = .idle
                log.error(error)
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
                call = streamVideo.call(callType: callType, callId: callId)
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

    open func requestTransaction(
        _ transaction: CXTransaction
    ) async throws {
        try await withCheckedThrowingContinuation { [callController] continuation in
            callController.request(transaction) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        } as Void
    }

    public func checkIfCallWasHandled(callId: String, type: String) {
        Task {
            let call = streamVideo.call(callType: type, callId: callId)
            let callState = try await call.get()
            let acceptedBy = callState.session?.acceptedBy ?? [:]
            let rejectedBy = callState.session?.rejectedBy ?? [:]
            let currentUserId = streamVideo.user.id
            let isAccepted = acceptedBy[currentUserId] != nil
            let isRejected = rejectedBy[currentUserId] != nil
            if (isAccepted || isRejected) && state == .idle {
                endCurrentCall()
            } else {
                createdBy = callState.createdBy.toUser
                let timeout = TimeInterval(callState.settings.ring.autoCancelTimeoutMs / 1000)
                ringingTimerCancellable = Foundation.Timer.publish(
                    every: timeout,
                    on: .main,
                    in: .default
                )
                .autoconnect()
                .sink { [weak self] _ in
                    log.debug("Detected ringing timeout, hanging up...")
                    self?.endCurrentCall()
                }
            }
        }
    }

    // MARK: - Private helpers

    private func subscribeToCallEvents() {
        Task {
            for await event in streamVideo.subscribe() {
                switch event {
                case .typeCallEndedEvent:
                    endCurrentCall()
                case let .typeCallAcceptedEvent(callAcceptedEvent):
                    if callAcceptedEvent.user.id == streamVideo.user.id, state == .idle {
                        endCurrentCall()
                    }
                    ringingTimerCancellable?.cancel()
                case let .typeCallRejectedEvent(callRejectedEvent):
                    if callRejectedEvent.user.id == streamVideo.user.id {
                        endCurrentCall()
                    } else if callRejectedEvent.user.id == createdBy?.id {
                        endCurrentCall()
                    }
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

extension CallKitAdapter: InjectionKey {
    public static var currentValue: CallKitAdapter = .init()
}

extension InjectedValues {
    public var callKitAdapter: CallKitAdapter {
        get { Self[CallKitAdapter.self] }
        set { Self[CallKitAdapter.self] = newValue }
    }
}
