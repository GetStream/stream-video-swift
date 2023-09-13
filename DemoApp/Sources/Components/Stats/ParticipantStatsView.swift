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
        
    var gridItem: GridItem {
        GridItem.init(
            .adaptive(minimum: itemSize + 2 * spacing),
            spacing: spacing,
            alignment: .topLeading
        )
    }
    
    init(call: Call, participant: CallParticipant) {
        _viewModel = StateObject(
            wrappedValue: ParticipantStatsViewModel(
                call: call,
                participant: participant
            )
        )
    }
    
    var body: some View {
        LazyVGrid(columns: [gridItem, gridItem], spacing: spacing) {
            ForEach(viewModel.statsEntries) { entry in
                VStack(spacing: spacing) {
                    Text(entry.title)
                        .font(fonts.caption1)
                        .lineLimit(1)
                    Text(entry.value)
                        .font(valueFont)
                }
                .frame(width: itemSize, height: itemSize / 2)
                .padding(.all, spacing)
                .background(Color(colors.background1))
                .cornerRadius(8)
            }
            Button {
                viewModel.allStatsShown = true
            } label: {
                Text("All stats")
                    .font(valueFont)
                    .foregroundColor(colors.text)
                    .frame(width: itemSize, height: itemSize / 2)
                    .padding(.all, spacing)
                    .background(Color(colors.background1))
                    .cornerRadius(8)
            }

        }
        .frame(width: 2 * itemSize + 4 * spacing)
        .padding()
        .background(colors.callControlsBackground)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .opacity(viewModel.statsEntries.count > 0 ? 1 : 0)
        .sheet(
            isPresented: $viewModel.allStatsShown,
            content: {
                RawStatsView(statsReport: viewModel.statsReport)
            }
        )
    }
    
    private var itemSize: CGFloat {
        if compacted {
            return 72
        } else {
            return 100
        }
    }
    
    private var valueFont: Font {
        if !compacted {
            return .headline
        } else {
            if #available(iOS 16.0, *) {
                return .system(.caption, weight: .bold)
            } else {
                return fonts.caption1
            }
        }
    }
    
    private var compacted: Bool {
        viewModel.call.state.participants.count > 3
    }
    
    private var spacing: CGFloat {
        compacted ? 4 : 8
    }
}
