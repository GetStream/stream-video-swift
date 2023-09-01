//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import UIKit
import Foundation
@preconcurrency import CallKit
import StreamVideo
import StreamVideoSwiftUI

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
        let configuration = CXProviderConfiguration()
        configuration.supportsVideo = true
        configuration.supportedHandleTypes = [.generic]
        configuration.iconTemplateImageData = UIImage(named: "logo")?.pngData()
        let provider = CXProvider(
            configuration: configuration
        )
        provider.setDelegate(self, queue: nil)
        let update = CXCallUpdate()
        let idComponents = callCid.components(separatedBy: ":")
        if idComponents.count >= 2  {
            self.callId = idComponents[1]
            self.callType = idComponents[0]
        }
        let callUUID = UUID()
        callKitId = callUUID
        update.localizedCallerName = displayName
        update.remoteHandle = CXHandle(type: .generic, value: callerId)
        update.hasVideo = true
        Task {
            await MainActor.run(body: {
                setupStreamVideoIfNeeded()
                connectStreamVideo()
            })
        }
        provider.reportNewIncomingCall(
            with: callUUID,
            update: update,
            completion: completion
        )
        checkIfCallWasHandled(callId: callId, type: callType)
    }
    
    private func checkIfCallWasHandled(callId: String, type: String) {
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
                await MainActor.run {
                    startTimer(timeout: TimeInterval(callState.settings.ring.autoCancelTimeoutMs / 1000))
                }
            }
        }
    }
    
    @objc func endCurrentCall() {
        guard let callKitId = callKitId else { return }
        let endCallAction = CXEndCallAction(call: callKitId)
        let transaction = CXTransaction(action: endCallAction)
        requestTransaction(transaction)
        self.callKitId = nil
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
    
    func providerDidReset(_ provider: CXProvider) {}
    
    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        if !callId.isEmpty {
            stopTimer()
            Task {
                await MainActor.run {
                    Task {
                        state = .joining
                        do {
                            self.call = streamVideo.call(callType: callType, callId: callId)
                            AppState.shared.activeCall = call
                            subscribeToCallEvents()
                            try await call?.accept()
                            try await call?.join()
                            state = .inCall
                            await MainActor.run {
                                action.fulfill()
                            }
                        } catch {
                            state = .idle
                        }
                        
                    }
                }
            }
        } else {
            action.fail()
        }
    }
    
    @MainActor
    private func setupStreamVideoIfNeeded() {
        guard let currentUser = AppState.shared.unsecureRepository.loadCurrentUser() else {
            return
        }
        if AppState.shared.streamVideo == nil {
            let streamVideo = StreamVideo(
                apiKey: AppEnvironment.apiKey.rawValue,
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
    
    private func connectStreamVideo() {
        Task {
            try await streamVideo.connect()
            subscribeToCallEvents()
        }
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
                    case .ended(_):
                        endCurrentCall()
                    case .rejected(let callInfo):
                        if callInfo.user?.id == streamVideo.user.id {
                            endCurrentCall()
                        } else if callInfo.user?.id == createdBy?.id {
                            endCurrentCall()
                        }
                    case .accepted(let callInfo):
                        if callInfo.user?.id == streamVideo.user.id && state == .idle {
                            endCurrentCall()
                        }
                    default:
                        log.debug("received call event")
                    }
                }
            }
        }
    }
    
    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        callKitId = nil
        stopTimer()
        Task {
            if call == nil {
                call = streamVideo.call(callType: callType, callId: callId)
            }
            try await call?.reject()
            call = nil
            createdBy = nil
            state = .idle
            await MainActor.run {
                AppState.shared.activeCall = nil
            }
            action.fulfill()
        }
    }
    
    private func stopTimer() {
        ringingTimer?.invalidate()
        ringingTimer = nil
    }
}
