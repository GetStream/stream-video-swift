//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

@available(iOS 15.0, *)
struct DemoBackgroundEffectSelector: View {

    var effects: [BackgroundEffect] = BackgroundEffect.allCases

    var body: some View {
        ScrollView(.horizontal) {
            HStack(alignment: .center) {
                ForEach(effects) { effect in
                    DemoEffectButton(effect: effect)
                }
            }
            .padding(8)
        }
    }
}

@available(iOS 15.0, *)
@MainActor
struct DemoEffectButton: View {

    @Injected(\.colors) var colors

    var effect: BackgroundEffect
    @ObservedObject var appState = AppState.shared

    private var isSelected: Bool {
        switch effect {
        case .none:
            appState.videoFilter == nil
        case .blur:
            appState.videoFilter?.id == VideoFilter.blurredBackground.id
        default:
            appState.videoFilter?.id == effect.rawValue
        }
    }

    var body: some View {
        Button {
            appState.videoFilter = isSelected ? nil : effect.filter
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
enum BackgroundEffect: String, CaseIterable, Identifiable {
    case none
    case blur
    case amsterdam1 = "amsterdam-1"
    case amsterdam2 = "amsterdam-2"
    case boulder1 = "boulder-1"
    case boulder2 = "boulder-2"
    case gradient1 = "gradient-1"
    case gradient2 = "gradient-2"
    case gradient3 = "gradient-3"

    var id: ObjectIdentifier { ObjectIdentifier(rawValue as NSString) }

    var filter: VideoFilter? {
        switch self {
        case .none:
            return nil
        case .blur:
            return .blurredBackground
        default:
            guard
                let image = UIImage(named: rawValue),
                let ciImage = CIImage(image: image)
            else {
                return nil
            }
            return VideoFilter.imageBackground(ciImage, id: rawValue)
        }
    }

    var image: Image {
        switch self {
        case .none:
            Image(systemName: "circle.slash")
        case .blur:
            Image(systemName: "square.stack.3d.forward.dottedline.fill")
        default:
            Image(rawValue)
        }
    }

    var padding: Double {
        switch self {
        case .none:
            10
        case .blur:
            10
        default:
            0
        }
    }
}
