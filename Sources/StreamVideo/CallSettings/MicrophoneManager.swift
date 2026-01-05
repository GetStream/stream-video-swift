//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// Handles the microphone state during a call.
public final class MicrophoneManager: ObservableObject, CallSettingsManager, @unchecked Sendable {
    
    internal let callController: CallController
    /// The status of the microphone.
    @Published public internal(set) var status: CallSettingsStatus
    let state = CallSettingsState()
    
    init(callController: CallController, initialStatus: CallSettingsStatus) {
        self.callController = callController
        status = initialStatus
    }
    
    /// Toggles the microphone state.
    public func toggle(
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line
    ) async throws {
        try await updateAudioStatus(
            status.next,
            file: file,
            function: function,
            line: line
        )
    }
    
    /// Enables the microphone.
    public func enable(
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line
    ) async throws {
        try await updateAudioStatus(
            .enabled,
            file: file,
            function: function,
            line: line
        )
    }
    
    /// Disables the microphone.
    public func disable(
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line
    ) async throws {
        try await updateAudioStatus(
            .disabled,
            file: file,
            function: function,
            line: line
        )
    }
    
    // MARK: - private
    
    private func updateAudioStatus(
        _ status: CallSettingsStatus,
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line
    ) async throws {
        try await updateState(
            newState: status.boolValue,
            current: self.status.boolValue,
            action: { [unowned self] state in
                try await callController.changeAudioState(
                    isEnabled: state,
                    file: file,
                    function: function,
                    line: line
                )
            },
            onUpdate: { _ in
                self.status = status
            }
        )
    }
}
