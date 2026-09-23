//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

@available(iOS 15.0, *)
struct DemoBackgroundEffectSelector: View {

    @Injected(\.videoAppearance) private var videoAppearance

    var effects: [BackgroundEffect] = BackgroundEffect.allCases

    var body: some View {
        ScrollView(.horizontal) {
            HStack(alignment: .center, spacing: tokens.layout.spacingXxs) {
                ForEach(effects) { effect in
                    DemoEffectButton(effect: effect)
                }
            }
        }
    }

    private var tokens: DesignSystemTokens { videoAppearance.tokens }
}

@available(iOS 15.0, *)
@MainActor
struct DemoEffectButton: View {

    @Injected(\.videoAppearance) private var videoAppearance

    var effect: BackgroundEffect
    @ObservedObject var appState = AppState.shared

    private var isSelected: Bool {
        switch effect {
        case .none:
            return appState.videoFilter == nil
        case .pixelate:
            return appState.videoFilter?.id == VideoFilter.pixelate.id
        case .blur:
            return appState.videoFilter?.id == VideoFilter.blur.id
        case .blurBackground:
            return appState.videoFilter?.id == VideoFilter.blurredBackground.id
        default:
            return appState.videoFilter?.id == effect.rawValue
        }
    }

    var body: some View {
        Button {
            appState.videoFilter = isSelected ? nil : effect.filter
        } label: {
            ZStack {
                Circle()
                    .fill(Color(tokens.colors.backgroundCoreOnElevation))
                    .overlay(
                        effect
                            .image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .padding(effect.padding)
                            .clipShape(Circle())
                    )
                    .clipped()
                    .frame(
                        width: tokens.layout.buttonVisualHeightMd,
                        height: tokens.layout.buttonVisualHeightMd
                    )

                if isSelected {
                    Circle()
                        .stroke(
                            Color(tokens.colors.borderUtilityActive),
                            lineWidth: 2
                        )
                        .frame(
                            width: selectionRingSize,
                            height: selectionRingSize
                        )
                }
            }
            .frame(
                width: tokens.layout.buttonVisualHeightLg,
                height: tokens.layout.buttonVisualHeightLg
            )
        }
        .buttonStyle(.plain)
    }

    private var selectionRingSize: CGFloat {
        tokens.layout.buttonVisualHeightLg - tokens.layout.spacingXxs
    }

    private var tokens: DesignSystemTokens { videoAppearance.tokens }
}

@available(iOS 15.0, *)
enum BackgroundEffect: String, CaseIterable, Identifiable {
    case none
    case blur
    case pixelate
    case blurBackground
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
        case .pixelate:
            return .pixelate
        case .blur:
            return .blur
        case .blurBackground:
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
            return Image(systemName: "circle.slash")
        case .pixelate:
            return Image(systemName: "square.grid.3x3.square")
        case .blur:
            return Image(systemName: "square.stack.3d.forward.dottedline.fill")
        case .blurBackground:
            return Image(systemName: "square.stack.3d.forward.dottedline")
        default:
            return Image(rawValue)
        }
    }

    var padding: Double {
        switch self {
        case .none:
            return 10
        case .pixelate, .blur, .blurBackground:
            return 10
        default:
            return 0
        }
    }
}
