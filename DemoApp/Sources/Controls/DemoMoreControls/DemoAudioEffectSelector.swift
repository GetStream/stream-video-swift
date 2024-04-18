//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI
#if canImport(StreamVideoNoiseCancellation)
import StreamVideoNoiseCancellation
#endif

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
        #if canImport(StreamVideoNoiseCancellation)
        case .noiseCancellation:
            return appState.audioFilter?.id == "noise-cancellation"
        #endif
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
    #if canImport(StreamVideoNoiseCancellation)
    case noiseCancellation
    #endif

    var id: ObjectIdentifier { ObjectIdentifier(rawValue as NSString) }

    var filter: AudioFilter? {
        switch self {
        case .none:
            return nil
        case .robot:
            return RobotVoiceFilter(pitchShift: 0.8)
        #if canImport(StreamVideoNoiseCancellation)
        case .noiseCancellation:
            let processor = NoiseCancellationProcessor()
            return NoiseCancellationFilter(
                name: "noise-cancellation",
                initialize: processor.initialize,
                process: processor.process,
                release: processor.release
            )
        #endif
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
        #if canImport(StreamVideoNoiseCancellation)
        case .noiseCancellation:
            return Image(systemName: "3.circle")
        #endif
        }
    }

    var padding: Double {
        10
    }
}
