//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// Handles the speaker state during a call.
public final class SpeakerManager: ObservableObject, CallSettingsManager, @unchecked Sendable {

    private struct Settings: Hashable {
        var speakerOn: Bool
        var audioOutputOn: Bool

        init(_ callSettings: CallSettings) {
            speakerOn = callSettings.speakerOn
            audioOutputOn = callSettings.audioOutputOn
        }
    }

    @Published public internal(set) var status: CallSettingsStatus
    @Published public internal(set) var audioOutputStatus: CallSettingsStatus

    weak var call: Call? {
        didSet {
            Task(disposableBag: disposableBag) { [weak self] in
                guard let self else {
                    return
                }
                await didUpdateCall(call)
            }
        }
    }

    internal let callController: CallController
    internal let state = CallSettingsState()

    private let disposableBag = DisposableBag()

    init(
        callController: CallController,
        initialSpeakerStatus: CallSettingsStatus,
        initialAudioOutputStatus: CallSettingsStatus
    ) {
        self.callController = callController
        status = initialSpeakerStatus
        audioOutputStatus = initialAudioOutputStatus
    }
    
    /// Toggles the speaker during a call.
    public func toggleSpeakerPhone() async throws {
        try await updateSpeakerStatus(status.next)
    }
    
    /// Enables the speaker during a call.
    public func enableSpeakerPhone() async throws {
        try await updateSpeakerStatus(.enabled)
    }
    
    /// Disables the speaker during a call.
    public func disableSpeakerPhone() async throws {
        try await updateSpeakerStatus(.disabled)
    }
    
    /// Enables the sound on the device.
    public func enableAudioOutput() async throws {
        try await updateAudioOutputStatus(.enabled)
    }
    
    /// Disables the sound on the device.
    public func disableAudioOutput() async throws {
        try await updateAudioOutputStatus(.disabled)
    }
    
    // MARK: - private
    
    private func updateSpeakerStatus(_ status: CallSettingsStatus) async throws {
        try await updateState(
            newState: status.boolValue,
            current: self.status.boolValue,
            action: { [unowned self] state in
                try await callController.changeSpeakerState(isEnabled: state)
            },
            onUpdate: { _ in
                self.status = status
            }
        )
    }
    
    private func updateAudioOutputStatus(_ status: CallSettingsStatus) async throws {
        try await updateState(
            newState: status.boolValue,
            current: audioOutputStatus.boolValue,
            action: { [unowned self] state in
                try await callController.changeSoundState(isEnabled: state)
            },
            onUpdate: { _ in
                self.audioOutputStatus = status
            }
        )
    }

    @MainActor
    private func didUpdateCall(_ call: Call?) {
        let observationKey = "call-settings-cancellable"
        disposableBag.remove(observationKey)

        guard let call else {
            return
        }

        let typeOfSelf = type(of: self)
        call
            .state
            .$callSettings
            .map { Settings($0) }
            .removeDuplicates()
            .log(.debug) { "\(typeOfSelf) callSettings updated speakerOn:\($0.speakerOn) audioOutputOn:\($0.audioOutputOn)." }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.status = $0.speakerOn ? .enabled : .disabled
                self?.audioOutputStatus = $0.audioOutputOn ? .enabled : .disabled
            }
            .store(in: disposableBag, key: observationKey)
    }
}
