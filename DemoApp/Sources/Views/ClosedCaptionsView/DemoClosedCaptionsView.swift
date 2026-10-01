//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct DemoClosedCaptionsView: View {

    @Injected(\.videoAppearance) private var videoAppearance

    @ObservedObject var viewModel: CallViewModel
    @State private var items: [CallClosedCaption] = []

    init(_ viewModel: CallViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        if AppEnvironment.closedCaptionsIntegration == .enabled {
            Group {
                if items.isEmpty {
                    EmptyView()
                } else {
                    VStack(spacing: tokens.layout.spacingXs) {
                        ForEach(items, id: \.hashValue) { item in
                            HStack(alignment: .top, spacing: tokens.layout.spacingXs) {
                                Text(item.speakerId)
                                    .foregroundColor(Color(tokens.colors.textOnAccent))

                                Text(item.text)
                                    .lineLimit(3)
                                    .foregroundColor(Color(tokens.colors.textOnAccent))
                                    .frame(maxWidth: .infinity)
                            }
                            .transition(.asymmetric(insertion: .move(edge: .bottom), removal: .move(edge: .top)))
                        }
                    }
                    .padding(.horizontal, tokens.layout.spacingMd)
                    .padding(.vertical, tokens.layout.spacingXs)
                    .background(Color(tokens.colors.backgroundCoreOverlayDarkStrong))
                    .animation(.default, value: items)
                }
            }
            .onReceive(viewModel.call?.state.$closedCaptions) { items = $0 }
        }
    }

    private var tokens: DesignSystemTokens { videoAppearance.tokens }
}
