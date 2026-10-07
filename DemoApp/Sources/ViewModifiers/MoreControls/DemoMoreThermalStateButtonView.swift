//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct DemoMoreThermalStateButtonView: View {

    @Injected(\.thermalStateObserver) private var thermalStateObserver
    @Injected(\.colors) private var colors
    @Injected(\.layout) private var layout
    @State private var thermalState = ProcessInfo.ThermalState.nominal

    var body: some View {
        Button {} label: {
            Label(
                title: { Text(text(for: thermalState)) },
                icon: { icon(for: thermalState) }
            )
            .frame(maxWidth: .infinity)
            .padding(.horizontal, layout.spacingMd)
        }
        .frame(height: layout.buttonVisualHeightMd)
        .buttonStyle(.borderless)
        .foregroundColor(Color(colors.textOnAccent))
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
            Color(colors.accentPrimary)
        case .fair:
            Color(colors.accentSuccess)
        case .serious:
            Color(colors.accentWarning)
        case .critical:
            Color(colors.accentError)
        @unknown default:
            Color(colors.accentNeutral)
        }
    }
}
