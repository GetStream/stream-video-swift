//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

@available(iOS 14.0, *)
struct LayoutMenuView: View {
    
    @ObservedObject var viewModel: CallViewModel
    
    var body: some View {
        Menu {
            LayoutMenuItem(
                title: L10n.Call.Current.layoutGrid,
                layout: .grid,
                selectedLayout: viewModel.participantsLayout
            ) { layout in
                viewModel.update(participantsLayout: layout)
            }
            LayoutMenuItem(
                title: L10n.Call.Current.layoutFullScreen,
                layout: .fullScreen,
                selectedLayout: viewModel.participantsLayout
            ) { layout in
                viewModel.update(participantsLayout: layout)
            }
            LayoutMenuItem(
                title: L10n.Call.Current.layoutSpotlight,
                layout: .spotlight,
                selectedLayout: viewModel.participantsLayout
            ) { layout in
                viewModel.update(participantsLayout: layout)
            }
        } label: {
            Label(L10n.Call.Current.layoutView, systemImage: "circle.grid.2x2.fill")
                .foregroundColor(.white)
        }
    }
}


struct LayoutMenuItem: View {
    
    var title: String
    var layout: ParticipantsLayout
    var selectedLayout: ParticipantsLayout
    var selectLayout: (ParticipantsLayout) -> ()
    
    var body: some View {
        Button {
            withAnimation {
                selectLayout(layout)
            }
        } label: {
            HStack {
                Text(title)
                Spacer()
                if selectedLayout == layout {
                    Image(systemName: "checkmark")
                }
            }
        }
    }
    
}
