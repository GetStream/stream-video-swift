//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct DemoClosedCaptionsView: View {

    @Injected(\.colors) private var colors

    var viewModel: CallViewModel

    init(_ viewModel: CallViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        if AppEnvironment.closedCaptionsIntegration == .enabled {
            PublisherSubscriptionView(
                initial: viewModel.call?.state.closedCaptions ?? [],
                publisher: viewModel.call?.state.$closedCaptions.eraseToAnyPublisher()
            ) { items in
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
        }
    }
}
