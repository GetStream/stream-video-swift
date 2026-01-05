//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct DemoClosedCaptionsView: View {

    @Injected(\.colors) private var colors

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
                    VStack {
                        ForEach(items, id: \.hashValue) { item in
                            HStack(alignment: .top) {
                                Text(item.speakerId)
                                    .foregroundColor(.init(colors.textLowEmphasis))

                                Text(item.text)
                                    .lineLimit(3)
                                    .foregroundColor(colors.text)
                                    .frame(maxWidth: .infinity)
                            }
                            .transition(.asymmetric(insertion: .move(edge: .bottom), removal: .move(edge: .top)))
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.75))
                    .animation(.default, value: items)
                }
            }
            .onReceive(viewModel.call?.state.$closedCaptions) { items = $0 }
        }
    }
}
