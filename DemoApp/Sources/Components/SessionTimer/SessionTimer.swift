//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

@MainActor class SessionTimer: ObservableObject {
    
    @Published var showTimerAlert: Bool = false {
        didSet {
            if showTimerAlert, let timerEndsAt {
                sessionEndCountdown?.cancel()
                sessionEndCountdown = nil
                secondsUntilEnd = timerEndsAt.timeIntervalSinceNow
                sessionEndCountdown = DefaultTimer
                    .publish(every: 1.0)
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] _ in
                        guard let self else { return }
                        if self.secondsUntilEnd <= 0 {
                            self.sessionEndCountdown?.cancel()
                            self.sessionEndCountdown = nil
                            self.secondsUntilEnd = 0
                            self.showTimerAlert = false
                            return
                        }
                        self.secondsUntilEnd -= 1
                    }
            } else if !showTimerAlert {
                sessionEndCountdown?.cancel()
                sessionEndCountdown = nil
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

    private var timer: AnyCancellable?
    private var sessionEndCountdown: AnyCancellable?

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
        timer?.cancel()
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
            timer = DefaultTimer
                .publish(every: timerInterval)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in
                    self?.showTimerAlert = true
                    self?.timer?.cancel()
                    self?.timer = nil
                }
        }
    }
    
    deinit {
        timer?.cancel()
        sessionEndCountdown?.cancel()
    }
}
