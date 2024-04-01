//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@preconcurrency import CallKit
import Foundation
import StreamVideo
import StreamVideoSwiftUI
import UIKit

final class CallKitService: NSObject, CXProviderDelegate, @unchecked Sendable {
    
    @Injected(\.streamVideo) var streamVideo
        
    var callId: String = ""
    var callType: String = ""
    
    private var call: Call?
    private let callEventsHandler = CallEventsHandler()
    
    private var state: CallKitState = .idle
    private var callKitId: UUID?
    private let callController = CXCallController()
    private var createdBy: User?
    private var ringingTimer: Foundation.Timer?
    
    private lazy var provider: CXProvider = {
        let configuration = CXProviderConfiguration()
        configuration.supportsVideo = true
        configuration.supportedHandleTypes = [.generic]
        configuration.iconTemplateImageData = UIImage(named: "logo")?.pngData()
        let provider = CXProvider(
            configuration: configuration
        )
        provider.setDelegate(self, queue: nil)
        return provider
    }()

    override init() {
        super.init()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(endCurrentCall),
            name: Notification.Name(CallNotification.callEnded),
            object: nil
        )
    }
        
    func reportIncomingCall(
        callCid: String,
        displayName: String,
        callerId: String,
        completion: @escaping (Error?) -> Void
    ) {
        let update = CXCallUpdate()
        let idComponents = callCid.components(separatedBy: ":")
        if idComponents.count >= 2 {
            callId = idComponents[1]
            callType = idComponents[0]
        }
        update.localizedCallerName = displayName
        update.remoteHandle = CXHandle(type: .generic, value: callerId)
        update.hasVideo = true
        
        let callUUID = UUID()
        callKitId = callUUID

        provider.reportNewIncomingCall(
            with: callUUID,
            update: update,
            completion: completion
        )

        Task {
            do {
                let (_, callState) = try await callAndState(
                    callId: callId,
                    callType: callType
                )

                if checkIfCallWasHandled(callState: callState) == false, state == .idle {
                    let result = await Task { @MainActor in
                        setupStreamVideoIfNeeded()
                        try await connectStreamVideo()
                    }.result
                    switch result {
                    case .success:
                        break
                    case let .failure(failure):
                        throw failure
                    }

                    startRingingTimer(for: callState)
                } else {
                    endCurrentCall()
                    completion(nil)
                }
            } catch {
                endCurrentCall()
                completion(error)
            }
        }
    }
    
    // MARK: - CXProviderDelegate

    func providerDidReset(_ provider: CXProvider) {}

    func provider(
        _ provider: CXProvider,
        perform action: CXAnswerCallAction
    ) {
        if !callId.isEmpty {
            stopTimer()
            if state == .inCall {
                /// If we already handled the call from the App's interface, wesimply fulfilll the action.
                /// - Important: We don't nullify the callKitId to allow us to end the CallKit call
                /// once we are done.
                action.fulfill()
            } else {
                Task { @MainActor in
                    state = .joining
                    do {
                        /// When the app isn't running streamVideo needs to be setUp prior to joining
                        /// the call.
                        setupStreamVideoIfNeeded()
                        if streamVideo.state.connection != .connected {
                            try await connectStreamVideo()
                        }
                        self.call = streamVideo.call(callType: callType, callId: callId)
                        AppState.shared.activeCall = call
                        subscribeToCallEvents()
                        try await call?.accept()
                        try await call?.join()
                        state = .inCall
                        action.fulfill()
                    } catch {
                        action.fail()
                    }
                }
            }
        } else {
            action.fail()
        }
    }

    func provider(
        _ provider: CXProvider,
        perform action: CXEndCallAction
    ) {
        callKitId = nil
        stopTimer()
        Task {
            if call == nil {
                call = streamVideo.call(callType: callType, callId: callId)
            }
            /// If we haven't accepted the call we simply reject it. If we have accepted it but the call ended
            /// we `leave`.
            try await call?.reject()
            call?.leave()
            call = nil
            createdBy = nil
            state = .idle
            await MainActor.run {
                AppState.shared.activeCall = nil
            }
            action.fulfill()
        }
    }

    // MARK: - Private Helpers

    @MainActor
    private func setupStreamVideoIfNeeded() {
        guard let currentUser = AppState.shared.unsecureRepository.loadCurrentUser() else {
            return
        }
        if AppState.shared.streamVideo == nil {
            let streamVideo = StreamVideo(
                apiKey: AppState.shared.apiKey,
                user: currentUser.userInfo,
                token: currentUser.token,
                videoConfig: VideoConfig(),
                tokenProvider: { result in
                    result(.success(currentUser.token))
                }
            )
            AppState.shared.streamVideo = streamVideo
        }
    }
    
    private func connectStreamVideo() async throws {
        try await streamVideo.connect()
        subscribeToCallEvents()
    }
    
    private func startTimer(timeout: TimeInterval) {
        guard state == .idle else { return }
        ringingTimer = Foundation.Timer.scheduledTimer(
            withTimeInterval: timeout,
            repeats: false,
            block: { [weak self] _ in
                guard let self = self else { return }
                log.debug("Detected ringing timeout, hanging up...")
                self.endCurrentCall()
            }
        )
    }
    
    private func subscribeToCallEvents() {
        Task {
            for await wsEvent in streamVideo.subscribe() {
                if let event = callEventsHandler.checkForCallEvents(from: wsEvent) {
                    switch event {
                    case .ended:
                        endCurrentCall()
                    case let .rejected(callInfo):
                        if callInfo.user?.id == streamVideo.user.id {
                            endCurrentCall()
                        } else if callInfo.user?.id == createdBy?.id {
                            endCurrentCall()
                        }
                    case let .accepted(callInfo):
                        if callInfo.user?.id == streamVideo.user.id, state == .idle, let callKitId {
                            state = .inCall
                            /// Ensure that we answer the call on CallKit in order to allow for
                            /// complete reporting and avoid cases where CallKit may stop
                            /// sending us VoIP notifications.
                            let answerCallAction = CXAnswerCallAction(call: callKitId)
                            let transaction = CXTransaction(action: answerCallAction)
                            requestTransaction(transaction)
                        }
                    default:
                        log.debug("received call event")
                    }
                } else {
                    switch wsEvent {
                    case .typeCallSessionParticipantLeftEvent:
                        /// We listen for the event so in the case we are the only ones remaining
                        /// in the call, we leave.
                        Task { @MainActor in
                            if let call, call.state.participants.count == 1 {
                                endCurrentCall()
                            }
                        }
                    default:
                        break
                    }
                }
            }
        }
    }
    
    private func stopTimer() {
        ringingTimer?.invalidate()
        ringingTimer = nil
    }

    private func requestTransaction(_ transaction: CXTransaction) {
        callController.request(transaction) { error in
            if let error = error {
                log.error("Error while executing the transaction", error: error)
            } else {
                log.debug("Transaction completed successfully")
            }
        }
    }

    @objc
    private func endCurrentCall() {
        guard let callKitId = callKitId else { return }
        let endCallAction = CXEndCallAction(call: callKitId)
        let transaction = CXTransaction(action: endCallAction)
        requestTransaction(transaction)
    }

    private func callAndState(
        callId: String,
        callType: String
    ) async throws -> (call: Call, state: GetCallResponse) {
        let call = streamVideo.call(callType: callType, callId: callId)
        let callState = try await call.get()
        return (call, callState)
    }

    private func checkIfCallWasHandled(callState: GetCallResponse) -> Bool {
        let acceptedBy = callState.call.session?.acceptedBy ?? [:]
        let rejectedBy = callState.call.session?.rejectedBy ?? [:]
        let currentUserId = streamVideo.user.id
        let isAccepted = acceptedBy[currentUserId] != nil
        let isRejected = rejectedBy[currentUserId] != nil
        let isRejectedByEveryoneElse = callState.members.count - 1 == rejectedBy.keys.filter { $0 != currentUserId }.count

        return (isAccepted || isRejected || isRejectedByEveryoneElse)
    }

    private func startRingingTimer(for callState: GetCallResponse) {
        createdBy = callState.call.createdBy.toUser
        startTimer(timeout: TimeInterval(callState.call.settings.ring.autoCancelTimeoutMs / 1000))
    }
}
