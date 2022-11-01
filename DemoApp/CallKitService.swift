//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import CallKit
import StreamVideo

class CallKitService: NSObject, CXProviderDelegate {
    
    @Injected(\.streamVideo) var streamVideo
        
    //TODO: load this from the notification
    var currentCallId = "callkit"
    
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
        
    func reportIncomingCall(completion: @escaping (Error?) -> Void) {
        let configuration = CXProviderConfiguration()
        configuration.supportsVideo = true
        let provider = CXProvider(
            configuration: configuration
        )
        provider.setDelegate(self, queue: nil)
        let update = CXCallUpdate()
        let callId = UUID()
        callKitId = callId
        update.remoteHandle = CXHandle(type: .generic, value: "You are receiving a call")
        provider.reportNewIncomingCall(
            with: callId,
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
        if !currentCallId.isEmpty {
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
//            let callController = streamVideo.makeCallController(callType: .default, callId: currentCallId)
//            Task {
                //TODO: change this to use the call creation flow.
//                _ = try? await callController.testSFU(
//                    callSettings: CallSettings(),
//                    url: "https://sfu2.fra1.gtstrm.com/rpc/twirp",
//                    token: MockTokenGenerator.generateToken(
//                        for: currentUser.userInfo,
//                        callId: currentCallId
//                    ),
//                    connectOptions: .testSFU
//                )
//                await MainActor.run {
//                    AppState.shared.activeCallController = callController
//                    action.fulfill()
//                }
//            }
        }
    }
    
    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        callKitId = nil
        streamVideo.leaveCall()
        action.fulfill()
    }
    
}

extension ConnectOptions {
    
    static let testSFU = ConnectOptions(iceServers: [
        ICEServerConfig(urls: ["stun:stun.l.google.com:19302"]),
        ICEServerConfig(urls: ["turn:sfu2.fra1.gtstrm.com:3478"], username: "video", password: "video")
    ])
}
