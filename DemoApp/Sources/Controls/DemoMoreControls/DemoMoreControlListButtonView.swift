//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct DemoMoreControlListButtonView: View {

    @Injected(\.colors) var colors

    var centered: Bool = false
    var action: () -> Void
    var label: String
    var icon: () -> Image

    var body: some View {
        Button {
            action()
        } label: {
            HStack {
                Label(
                    title: { Text(label) },
                    icon: { icon() }
                )

                if !centered {
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal)
        }
        .frame(height: 40)
        .buttonStyle(.borderless)
        .foregroundColor(colors.white)
        .background(Color(colors.participantBackground))
        .clipShape(Capsule())
        .frame(maxWidth: .infinity)
    }
}

@MainActor
struct DemoRaiseHandToggleButtonView: View {

    @ObservedObject var reactionsHelper = AppState.shared.reactionsHelper
    @ObservedObject var viewModel: CallViewModel

    init(viewModel: CallViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        DemoMoreControlListButtonView(
            centered: true,
            action: { reactionsHelper.send(reaction: .raiseHand) },
            label: currentUserHasRaisedHand ? "Lower Hand" : "Raise Hand"
        ) {
            Image(
                systemName: currentUserHasRaisedHand
                    ? Reaction.lowerHand.iconName
                    : Reaction.raiseHand.iconName
            )
        }
    }

    private var currentUserHasRaisedHand: Bool {
        guard let userId = viewModel.localParticipant?.userId else {
            return false
        }

        return reactionsHelper
            .activeReactions[userId]?
            .first(where: { $0.id == .raiseHand }) != nil
    }
}

@available(iOS 15.0, *)
struct DemoFiltersButtonView: View {
    
    @Injected(\.colors) var colors
    @Injected(\.fonts) var fonts

    @ObservedObject private var appState = AppState.shared

    private let imageBackgroundFilter: VideoFilter? = {
        if let backgroundImage = CIImage(resource: "call-background-filter-image", ofType: "jpg") {
            return VideoFilter.imageBackground(backgroundImage)
        } else {
            return nil
        }
    }()

    @State private var selectedVideoFilter: VideoFilter? = AppState.shared.videoFilter {
        didSet {
            appState.videoFilter = selectedVideoFilter
        }
    }

    private var availableFilters: [VideoFilter] {
        [blurBackgroundFilter, imageBackgroundFilter].compactMap { $0 }
    }

    private let blurBackgroundFilter: VideoFilter = .blurredBackground

    var body: some View {
        Menu(content: {
            ForEach(availableFilters, id: \.id) { element in
                Button(
                    action: { selectedVideoFilter = selectedVideoFilter?.id == element.id ? nil : element } ,
                    label: {
                        Label {
                            Text(element.name)
                        } icon: {
                            selectedVideoFilter?.id == element.id 
                            ? Image(systemName: "checkmark")
                            : nil
                        }

                    }
                )
            }
        }, label: {
            HStack {
                Label(
                    title: { Text("Video filters") },
                    icon: { Image(systemName: "camera.filters") }
                )

                Spacer()

                if let selectedVideoFilter {
                    Text(selectedVideoFilter.name)
                        .font(fonts.caption1)
                        .foregroundColor(Color(colors.textLowEmphasis))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal)
        })
        .frame(height: 40)
        .buttonStyle(.borderless)
        .foregroundColor(colors.white)
        .background(Color(colors.participantBackground))
        .clipShape(Capsule())
        .frame(maxWidth: .infinity)
    }
}
