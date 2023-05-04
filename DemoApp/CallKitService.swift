//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import UIKit
import Foundation
@preconcurrency import CallKit
import StreamVideo

class CallKitService: NSObject, CXProviderDelegate, @unchecked Sendable {
    
    @Injected(\.streamVideo) var streamVideo
        
    var callId: String = ""
    var callType: String = ""
    
    private var call: Call?
    
    private var callKitId: UUID?
    private let callController = CXCallController()
    
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
                log.error("Error while executing the transaction \(error.localizedDescription)")
            } else {
                log.debug("Transaction completed successfully")
            }
        }
    }
    
    func providerDidReset(_ provider: CXProvider) {}
    
    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        if !callId.isEmpty {
            Task {
                await MainActor.run {
                    Task {
                        try await streamVideo.connect()
                        self.call = streamVideo.makeCall(callType: callType, callId: callId)
                        AppState.shared.activeCall = call
                        subscribeToCallEvents()
                        try await call?.join()
                        await MainActor.run {
                            action.fulfill()
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
        guard let currentUser = UnsecureUserRepository.shared.loadCurrentUser() else {
            return
        }
        if AppState.shared.streamVideo == nil {
            let streamVideo = StreamVideo(
                apiKey: Config.apiKey,
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
    
    private func subscribeToCallEvents() {
        Task {
            for await event in streamVideo.callEvents() {
                switch event {
                case .canceled(_), .ended(_):
                    endCurrentCall()
                default:
                    log.debug("received call event")
                }
            }
        }
    }
    
    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        callKitId = nil
        call?.leave()
        call = nil
        Task {
            await MainActor.run {
                AppState.shared.activeCall = nil
            }
        }
        action.fulfill()
    }
    
}
