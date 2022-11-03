//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
@preconcurrency import CallKit
@preconcurrency import StreamVideo

class CallKitService: NSObject, CXProviderDelegate {
    
    @Injected(\.streamVideo) var streamVideo
        
    var callId: String = ""
    var callType: String = ""
    
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
        
    func reportIncomingCall(callCid: String, completion: @escaping (Error?) -> Void) {
        let configuration = CXProviderConfiguration()
        configuration.supportsVideo = true
        configuration.supportedHandleTypes = [.generic]
        let provider = CXProvider(
            configuration: configuration
        )
        provider.setDelegate(self, queue: nil)
        let update = CXCallUpdate()
        let idComponents = callCid.components(separatedBy: ":")
        guard idComponents.count >= 2 else {
            //TODO: handle this case.
            return
        }
        self.callId = idComponents[1]
        self.callType = idComponents[0]
        //TODO: add mapping
        callKitId = UUID()
        update.remoteHandle = CXHandle(type: .generic, value: "You are receiving a call")
        provider.reportNewIncomingCall(
            with: callKitId!,
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
    
    func providerDidReset(_ provider: CXProvider) {
        
    }
    
    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        guard let currentUser = UnsecureUserRepository.shared.loadCurrentUser() else {
            action.fail()
            return
        }
        if !callId.isEmpty {
            if AppState.shared.streamVideo == nil {
                let streamVideo = StreamVideo(
                    apiKey: "key1",
                    user: currentUser.userInfo,
                    token: currentUser.token,
                    videoConfig: VideoConfig(
                        persitingSocketConnection: true,
                        joinVideoCallInstantly: false
                    ),
                    tokenProvider: { result in
                        result(.success(currentUser.token))
                    }
                )
                AppState.shared.streamVideo = streamVideo
            }
            let callType: CallType = .init(name: callType)
            let callController = streamVideo.makeCallController(callType: callType, callId: callId)
            Task {
                //TODO: change this to use the call creation flow.
                _ = try await callController.joinCall(
                    callType: callType,
                    callId: callId,
                    callSettings: CallSettings(),
                    videoOptions: VideoOptions(),
                    participantIds: []
                )
                await MainActor.run {
                    AppState.shared.activeCallController = callController
                    action.fulfill()
                }
            }
        }
    }
    
    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        callKitId = nil
        streamVideo.leaveCall()
        action.fulfill()
    }
    
}
