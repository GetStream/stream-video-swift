//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

//
//  SharingIndicator.swift
//  StreamVideo
//
//  Created by Ilias Pavlidakis on 9/6/25.
//

import StreamVideo
import SwiftUI

public struct SharingIndicator: View, @preconcurrency Equatable {

    @Binding var sharingPopupDismissed: Bool
    var actionHandler: () -> Void

    public init(
        viewModel: CallViewModel,
        sharingPopupDismissed: Binding<Bool>
    ) {
        self.init(
            sharingPopupDismissed: sharingPopupDismissed,
            actionHandler: { [weak viewModel] in viewModel?.stopScreensharing() }
        )
    }

    public init(
        sharingPopupDismissed: Binding<Bool>,
        actionHandler: @escaping () -> Void
    ) {
        _sharingPopupDismissed = sharingPopupDismissed
        self.actionHandler = actionHandler
    }

    public static func == (
        lhs: SharingIndicator,
        rhs: SharingIndicator
    ) -> Bool {
        lhs.sharingPopupDismissed == rhs.sharingPopupDismissed
    }

    public var body: some View {
        HStack {
            Text(L10n.Call.Current.sharing)
                .font(.headline)
            Divider()
            Button {
                actionHandler()
            } label: {
                Text(L10n.Call.Current.stopSharing)
                    .font(.headline)
            }
            Button {
                sharingPopupDismissed = true
            } label: {
                Image(systemName: "xmark")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 14)
            }
            .padding(.leading, 4)
        }
        .padding(.all, 8)
        .modifier(ShadowViewModifier())
    }
}
