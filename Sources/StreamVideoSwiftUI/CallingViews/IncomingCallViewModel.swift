//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamVideo

@MainActor
public class IncomingViewModel: ObservableObject {
    
    @Injected(\.streamVideo) var streamVideo
    
    public private(set) var callInfo: IncomingCall
    
    @Published public var hideIncomingCallScreen = false
    
    var callParticipants: [Member] {
        callInfo.members.filter { $0.id != streamVideo.user.id }
    }
    
    private var ringingTimer: Foundation.Timer?
    
    public init(callInfo: IncomingCall) {
        self.callInfo = callInfo
        startTimer(timeout: callInfo.timeout)
    }
    
    private func startTimer(timeout: TimeInterval) {
        ringingTimer = Foundation.Timer.scheduledTimer(
            withTimeInterval: timeout,
            repeats: false,
            block: { [weak self] _ in
                guard let self = self else { return }
                log.debug("Detected ringing timeout, hanging up...")
                Task {
                    await MainActor.run {
                        self.hideIncomingCallScreen = true
                    }
                }
            }
        )
    }
    
    public func stopTimer() {
        ringingTimer?.invalidate()
        ringingTimer = nil
    }
}
