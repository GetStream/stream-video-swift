//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import CallKit
import StreamVideo

class CallKitService: NSObject, CXProviderDelegate {
    
    @Injected(\.streamVideo) var streamVideo
        
    //TODO: load this from the notification
    var currentCallId = "123"
    
    func reportIncomingCall(completion: @escaping (Error?) -> Void) {
        let configuration = CXProviderConfiguration()
        configuration.supportsVideo = true
        let provider = CXProvider(
            configuration: configuration
        )
        provider.setDelegate(self, queue: nil)
        let update = CXCallUpdate()
        update.remoteHandle = CXHandle(type: .generic, value: "You are receiving a call")
        provider.reportNewIncomingCall(
            with: UUID(),
            update: update,
            completion: completion
        )
    }
    
    func providerDidReset(_ provider: CXProvider) {
        
    }
    
    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        if !currentCallId.isEmpty {
            Task {
                _ = try? await streamVideo.joinCall(
                    callType: .init(name: "video"),
                    callId: currentCallId,
                    videoOptions: VideoOptions()
                )
            }

        }
        
        action.fulfill()
    }
    
    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        action.fulfill()
    }
    
}
