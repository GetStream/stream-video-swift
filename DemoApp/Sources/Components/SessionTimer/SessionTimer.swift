//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

class SessionTimer: ObservableObject {
    
    @Published var showTimerAlert: Bool = false
    
    private var call: Call?
    private var cancellables = Set<AnyCancellable>()
    private var timerEndsAt: Date? {
        didSet {
            timer?.invalidate()
            timer = nil
            if let timerEndsAt {
                let alertDate = timerEndsAt.addingTimeInterval(-alertInterval)
                let timerInterval = alertDate.timeIntervalSinceNow
                if timerInterval <= 0 {
                    showTimerAlert = true
                    return
                }
                log.debug("Starting a timer in \(timerInterval) seconds")
                timer = Timer.scheduledTimer(
                    withTimeInterval: timerInterval,
                    repeats: false,
                    block: { [weak self] _ in
                        log.debug("Showing timer alert")
                        self?.showTimerAlert = true
                    }
                )
            }
        }
    }
    
    private var timer: Timer?
    private let alertInterval: TimeInterval
    
    @MainActor init(
        call: Call?,
        alertInterval: TimeInterval
    ) {
        self.call = call
        self.alertInterval = alertInterval
        timerEndsAt = call?.state.session?.timerEndsAt
        self.call?.state.$session.sink { [weak self] response in
            guard let self else { return }
            if response?.timerEndsAt != self.timerEndsAt {
                self.timerEndsAt = response?.timerEndsAt
            }
        }
        .store(in: &cancellables)
    }
}
