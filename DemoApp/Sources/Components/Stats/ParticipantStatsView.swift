//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct ParticipantStatsView: View {

    @StateObject var viewModel: ParticipantStatsViewModel
    @Injected(\.colors) var colors
    @Injected(\.fonts) var fonts

    @Binding private var presentationBinding: Bool
    private var availableFrame: CGRect
    private var spacing: CGFloat = 8

    init(
        call: Call,
        participant: CallParticipant,
        presentationBinding: Binding<Bool>,
        availableFrame: CGRect
    ) {
        _viewModel = StateObject(
            wrappedValue: ParticipantStatsViewModel(
                call: call,
                participant: participant
            )
        )
        self._presentationBinding = presentationBinding
        self.availableFrame = availableFrame
    }

    var body: some View {
        Group {
            if availableFrame == .zero {
                Text("Loading ...")
            } else {
                ScrollView {
                    LazyVGrid(columns: [.init(.adaptive(minimum: itemSize.width))], spacing: spacing) {
                        if viewModel.statsEntries.isEmpty {
                            tileView {
                                VStack {
                                    Text("Fetching stats...")
                                        .font(valueFont)
                                    ProgressView()
                                }
                            }
                        } else {
                            ForEach(viewModel.statsEntries) { entry in
                                tileView {
                                    VStack(alignment: .center, spacing: spacing) {
                                        Spacer()
                                        Text(entry.title)
                                            .font(fonts.caption1)
                                            .lineLimit(1)
                                        Text(entry.value)
                                            .font(valueFont)
                                        Spacer()
                                    }
                                }
                            }

                            tileView {
                                Button {
                                    viewModel.allStatsShown = true
                                } label: {
                                    Text("All stats")
                                        .font(valueFont)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Stats")
        .background(colors.callControlsBackground)
        .sheet(
            isPresented: $viewModel.allStatsShown,
            content: {
                RawStatsView(statsReport: viewModel.statsReport)
            }
        )
        .toolbar(content: {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    presentationBinding = false
                } label: {
                    Text("Close")
                        .foregroundColor(colors.text)
                }
            }
        })
    }

    @ViewBuilder
    private func tileView(@ViewBuilder _ content: () -> some View) -> some View {
        content()
            .frame(height: floor(itemSize.height))
            .frame(maxWidth: .infinity)
            .background(Color(colors.background1))
            .cornerRadius(8)
    }

    private var valueFont: Font {
        if #available(iOS 16.0, *) {
            return .system(.caption, weight: .bold)
        } else {
            return fonts.caption1
        }
    }

    private var columns: CGFloat {
        2
    }

    private var rows: CGFloat {
        3
    }

    private var itemSize: CGSize {
        .init(
            width: (availableFrame.width / columns) - (columns - 1) * spacing,
            height: (availableFrame.height / rows) - (rows - 1) * spacing
        )
    }
}
