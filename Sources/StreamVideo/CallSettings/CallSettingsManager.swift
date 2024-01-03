//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

protocol CallSettingsManager {
    
    var state: CallSettingsState { get }
    
    func updateState(
        newState state: Bool,
        current: Bool,
        action: (Bool) async throws  -> (),
        onUpdate: @Sendable (Bool) -> ()
    ) async throws
}

extension CallSettingsManager {
    func updateState(
        newState state: Bool,
        current: Bool,
        action: (Bool) async throws  -> (),
        onUpdate: @Sendable (Bool) -> ()
    ) async throws {
        let updatingState = await self.state.updatingState
        if state == current || updatingState == state {
            return
        }
        await self.state.setUpdatingState(state)
        try await action(state)
        await MainActor.run {
            onUpdate(state)
        }
        await self.state.setUpdatingState(nil)
    }
}

actor CallSettingsState {
    var updatingState: Bool?
    func setUpdatingState(_ state: Bool?) {
        self.updatingState = state
    }
}

public enum CallSettingsStatus: String, Sendable {
    case enabled
    case disabled
    
    var next: Self {
        self == .enabled ? .disabled : .enabled
    }
    
    var boolValue: Bool {
        self == .enabled ? true : false
    }
}
