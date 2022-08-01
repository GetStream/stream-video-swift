//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import CallKit

class CallKitService: NSObject, CXProviderDelegate {
    
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
        action.fulfill()
    }
    
    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        action.fulfill()
    }
    
}
