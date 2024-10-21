//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct ThermalStateViewModifier: ViewModifier {

    @Injected(\.thermalStateObserver) var thermalStateObserver

    @State private var toast: Toast? = nil
    @State private var originalIncomingVideoSettings: IncomingVideoQualitySettings

    private var call: Call?

    init(_ call: Call?) {
        self.call = call
        originalIncomingVideoSettings = call?.state.incomingVideoQualitySettings ?? .none
    }

    func body(content: Content) -> some View {
        if AppEnvironment.thermalStateManagement == .enabled, call != nil {
            content
                .toastView(toast: $toast)
                .onReceive(
                    thermalStateObserver
                        .statePublisher
                        .removeDuplicates()
                ) { didUpdateThermalState($0) }
        } else {
            content
        }
    }

    // MARK: - Private helpers

    private var overrideAlreadyApplied: Bool {
        call?.state.incomingVideoQualitySettings == .disabled(group: .all)
    }

    @MainActor
    private func didUpdateThermalState(_ state: ProcessInfo.ThermalState) {
        switch state {
        case .serious where overrideAlreadyApplied == false, .critical where overrideAlreadyApplied == false:
            toast = .init(
                style: .warning,
                message: "Device temperature is higher than expected. We will disable incoming video tracks to help the device improve its thermal state.",
                placement: .top,
                duration: 5
            )
            Task {
                await call?.setIncomingVideoQualitySettings(.disabled(group: .all))
            }
        case .serious, .critical:
            break
        default:
            toast = nil
            if overrideAlreadyApplied {
                toast = .init(
                    style: .info,
                    message: "Device temperature is now back to normal level. We will be re-applying your initial incoming video settings.",
                    placement: .top,
                    duration: 5
                )
                Task {
                    await call?.setIncomingVideoQualitySettings(originalIncomingVideoSettings)
                }
            }
        }
    }
}
