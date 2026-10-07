//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct DemoClosedCaptionsView: View {

    @Injected(\.colors) private var colors
    @Injected(\.layout) private var layout

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
                    VStack(spacing: layout.spacingXs) {
                        ForEach(items, id: \.hashValue) { item in
                            HStack(alignment: .top, spacing: layout.spacingXs) {
                                Text(item.speakerId)
                                    .foregroundColor(Color(colors.textOnAccent))

                                Text(item.text)
                                    .lineLimit(3)
                                    .foregroundColor(Color(colors.textOnAccent))
                                    .frame(maxWidth: .infinity)
                            }
                            .transition(.asymmetric(insertion: .move(edge: .bottom), removal: .move(edge: .top)))
                        }
                    }
                    .padding(.horizontal, layout.spacingMd)
                    .padding(.vertical, layout.spacingXs)
                    .background(Color(colors.backgroundCoreOverlayDarkStrong))
                    .animation(.default, value: items)
                }
            }
            .onReceive(viewModel.call?.state.$closedCaptions) { items = $0 }
        }
    }
}
