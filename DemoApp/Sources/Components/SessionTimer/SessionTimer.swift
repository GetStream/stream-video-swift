//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

@MainActor class SessionTimer: ObservableObject {
    
    @Published var showTimerAlert: Bool = false {
        didSet {
            if showTimerAlert, let timerEndsAt {
                sessionEndCountdown?.invalidate()
                secondsUntilEnd = timerEndsAt.timeIntervalSinceNow
                sessionEndCountdown = Timer.scheduledTimer(
                    withTimeInterval: 1.0,
                    repeats: true,
                    block: { [weak self] _ in
                        guard let self else { return }
                        Task { @MainActor in
                            if self.secondsUntilEnd <= 0 {
                                self.sessionEndCountdown?.invalidate()
                                self.sessionEndCountdown = nil
                                self.secondsUntilEnd = 0
                                self.showTimerAlert = false
                                return
                            }
                            self.secondsUntilEnd -= 1
                        }
                    }
                )
            } else if !showTimerAlert {
                sessionEndCountdown?.invalidate()
                secondsUntilEnd = 0
            }
        }
    }
    
    @Published var secondsUntilEnd: TimeInterval = 0

    private var call: Call?
    private var cancellables = Set<AnyCancellable>()
    private var timerEndsAt: Date? {
        didSet {
            setupTimerIfNeeded()
        }
    }

    private var timer: Timer?
    private var sessionEndCountdown: Timer?
    
    private let alertInterval: TimeInterval
    
    private var extendDuration: TimeInterval
    
    private let changeMaxDurationPermission = Permission(
        rawValue: OwnCapability.changeMaxDuration.rawValue
    )
    
    let extensionTime: TimeInterval
    
    var showExtendCallDurationButton: Bool {
        call?.state.ownCapabilities.contains(.changeMaxDuration) == true
    }

    init(
        call: Call?,
        alertInterval: TimeInterval,
        extendDuration: TimeInterval = 120
    ) {
        self.call = call
        self.alertInterval = alertInterval
        self.extendDuration = extendDuration
        extensionTime = extendDuration
        timerEndsAt = call?.state.session?.timerEndsAt
        setupTimerIfNeeded()
        subscribeForSessionUpdates()
    }
    
    func extendCallDuration() {
        guard let call else { return }
        Task {
            do {
                let newDuration = (call.state.settings?.limits.maxDurationSeconds ?? 0) + Int(extendDuration)
                extendDuration += extendDuration
                log.debug("Extending call duration to \(newDuration) seconds")
                try await call.update(settingsOverride: .init(limits: .init(maxDurationSeconds: newDuration)))
                showTimerAlert = false
            } catch {
                log.error("Error extending call duration \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - private
    
    private func subscribeForSessionUpdates() {
        call?.state.$session.sink { [weak self] response in
            guard let self else { return }
            if response?.timerEndsAt != self.timerEndsAt {
                self.timerEndsAt = response?.timerEndsAt
            }
        }
        .store(in: &cancellables)
    }
    
    private func setupTimerIfNeeded() {
        timer?.invalidate()
        timer = nil
        showTimerAlert = false
        if let timerEndsAt {
            let alertDate = timerEndsAt.addingTimeInterval(-alertInterval)
            let timerInterval = alertDate.timeIntervalSinceNow
            if timerInterval < 0 {
                showTimerAlert = true
                return
            }
            log.debug("Starting a timer in \(timerInterval) seconds")
            timer = Timer.scheduledTimer(
                withTimeInterval: timerInterval,
                repeats: false,
                block: { [weak self] _ in
                    guard let self else { return }
                    log.debug("Showing timer alert")
                    Task { @MainActor in
                        self.showTimerAlert = true
                    }
                }
            )
        }
    }

    @MainActor
    deinit {
        timer?.invalidate()
        sessionEndCountdown?.invalidate()
    }
}
