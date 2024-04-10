//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

@available(iOS 15.0, *)
struct DemoAudioEffectSelector: View {

    var effects: [AudioEffect] = AudioEffect.allCases

    var body: some View {
        ScrollView(.horizontal) {
            HStack(alignment: .center) {
                ForEach(effects) { effect in
                    DemoAudioEffectButton(effect: effect)
                }
            }
            .padding(8)
        }
    }
}

@available(iOS 15.0, *)
@MainActor
struct DemoAudioEffectButton: View {

    @Injected(\.colors) var colors

    var effect: AudioEffect
    @ObservedObject var appState = AppState.shared

    private var isSelected: Bool {
        switch effect {
        case .none:
            return appState.audioFilter == nil
        case .robot:
            return appState.audioFilter?.id.hasPrefix("robot") == true
        case .c5ns20949d:
            return appState.audioFilter?.id == StreamNoiseCancellationFilter.no1.id
        case .c5swc9ac8f:
            return appState.audioFilter?.id == StreamNoiseCancellationFilter.no2.id
        case .c6fsced125:
            return appState.audioFilter?.id == StreamNoiseCancellationFilter.no3.id
        }
    }

    var body: some View {
        Button {
            appState.audioFilter = isSelected ? nil : effect.filter
        } label: {
            Circle()
                .fill(Color(colors.participantBackground))
                .overlay(
                    effect
                        .image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .padding(effect.padding)
                        .clipShape(Circle())
                )
                .clipped()
                .frame(width: 44, height: 44)
                .overlay(Circle().stroke(isSelected ? colors.text : .clear))
        }
        .buttonStyle(.plain)
    }
}

@available(iOS 15.0, *)
enum AudioEffect: String, CaseIterable, Identifiable {
    case none
    case robot
    case c5ns20949d
    case c5swc9ac8f
    case c6fsced125

    var id: ObjectIdentifier { ObjectIdentifier(rawValue as NSString) }

    var filter: AudioFilter? {
        switch self {
        case .none:
            return nil
        case .robot:
            return RobotVoiceFilter(pitchShift: 0.8)
        case .c5ns20949d:
            return StreamNoiseCancellationFilter.no1
        case .c5swc9ac8f:
            return StreamNoiseCancellationFilter.no2
        case .c6fsced125:
            return StreamNoiseCancellationFilter.no3
        }
    }

    var image: Image {
        switch self {
        case .none:
            if #available(iOS 16.0, *) {
                return Image(systemName: "waveform.slash")
            } else {
                return Image(systemName: "circle.slash")
            }
        case .robot:
            return Image(systemName: "waveform")
        case .c5ns20949d:
            return Image(systemName: "1.circle")
        case .c5swc9ac8f:
            return Image(systemName: "2.circle")
        case .c6fsced125:
            return Image(systemName: "3.circle")
        }
    }

    var padding: Double {
        10
    }
}
