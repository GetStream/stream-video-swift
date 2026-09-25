//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct DemoMoreThermalStateButtonView: View {

    @Injected(\.thermalStateObserver) private var thermalStateObserver
    @Injected(\.videoAppearance) private var videoAppearance
    @State private var thermalState = ProcessInfo.ThermalState.nominal

    var body: some View {
        Button {} label: {
            Label(
                title: { Text(text(for: thermalState)) },
                icon: { icon(for: thermalState) }
            )
            .frame(maxWidth: .infinity)
            .padding(.horizontal, tokens.layout.spacingMd)
        }
        .frame(height: tokens.layout.buttonVisualHeightMd)
        .buttonStyle(.borderless)
        .foregroundColor(Color(tokens.colors.textOnAccent))
        .background(background(for: thermalState))
        .clipShape(Capsule())
        .frame(maxWidth: .infinity)
        .disabled(true)
        .onReceive(thermalStateObserver.statePublisher) { thermalState = $0 }
    }

    private func text(for thermalState: ProcessInfo.ThermalState) -> String {
        switch thermalState {
        case .nominal:
            return "Nominal"
        case .fair:
            return "Fair"
        case .serious:
            return "Serious"
        case .critical:
            return "Critical"
        @unknown default:
            return "Unknown"
        }
    }

    @ViewBuilder
    private func icon(for thermalState: ProcessInfo.ThermalState) -> some View {
        switch thermalState {
        case .nominal:
            Image(systemName: "thermometer.low")
        case .fair:
            Image(systemName: "thermometer.medium")
        case .serious:
            Image(systemName: "thermometer.high")
        case .critical:
            Image(systemName: "flame")
        @unknown default:
            Image(systemName: "thermometer.medium.slash")
        }
    }

    @ViewBuilder
    private func background(for thermalState: ProcessInfo.ThermalState) -> some View {
        switch thermalState {
        case .nominal:
            Color(tokens.colors.accentPrimary)
        case .fair:
            Color(tokens.colors.accentSuccess)
        case .serious:
            Color(tokens.colors.accentWarning)
        case .critical:
            Color(tokens.colors.accentError)
        @unknown default:
            Color(tokens.colors.accentNeutral)
        }
    }

    private var tokens: DesignSystemTokens { videoAppearance.tokens }
}
