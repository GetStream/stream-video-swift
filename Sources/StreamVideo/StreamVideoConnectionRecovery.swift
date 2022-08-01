//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

extension StreamVideo: ConnectionStateDelegate {
    func webSocketClient(_ client: WebSocketClient, didUpdateConnectionState state: WebSocketConnectionState) {
        connectionStatus = .init(webSocketConnectionState: state)        
        connectionRecoveryHandler?.webSocketClient(client, didUpdateConnectionState: state)
    }
    
    private func refreshToken(
        completion: ((Error?) -> Void)?
    ) {
        guard let tokenProvider = userConnectionProvider?.tokenProvider else {
            return log.assertionFailure(
                "In case if token expiration is enabled on backend you need to provide a way to reobtain it via `tokenProvider` on ChatClient"
            )
        }
        
        let reconnectionDelay = tokenExpirationRetryStrategy.getDelayAfterTheFailure()
        
        tokenRetryTimer = self.timerType
            .schedule(
                timeInterval: reconnectionDelay,
                queue: .main
            ) {
                //TODO: Check this
                tokenProvider { result in
                    switch result {
                    case .success(let token):
                        self.token = token
                        self.tokenExpirationRetryStrategy.resetConsecutiveFailures()
                        completion?(nil)
                    case .failure(let error):
                        completion?(error)
                    }
                }
            }
    }
    
}
