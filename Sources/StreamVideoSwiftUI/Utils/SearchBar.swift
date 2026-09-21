//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

/// Search bar used in the message search.
struct SearchBar: View, KeyboardReadable {

    @Injected(\.videoAppearance) private var videoAppearance

    @Binding var text: String
    @State private var isEditing = false

    var body: some View {
        HStack {
            TextField(L10n.Call.Participants.search, text: $text)
                .padding(layout.spacingXs)
                .padding(.leading, layout.spacingXs)
                .padding(.horizontal, layout.spacing2xl)
                .background(Color(colors.backgroundCoreSurfaceDefault))
                .clipShape(RoundedRectangle(cornerRadius: layout.radiusXl, style: .continuous))
                .overlay(
                    HStack {
                        videoAppearance.images.searchIcon
                            .customizable()
                            .foregroundColor(Color(colors.textSecondary))
                            .frame(maxHeight: 18)
                            .padding(.leading, layout.spacingSm)

                        Spacer()

                        if !self.text.isEmpty {
                            Button(action: {
                                self.text = ""
                            }) {
                                videoAppearance.images.searchCloseIcon
                                    .customizable()
                                    .frame(width: 18, height: 18)
                                    .foregroundColor(Color(colors.textSecondary))
                                    .padding(.trailing, layout.spacingXs)
                            }
                        }
                    }
                )
                .padding(.horizontal, layout.spacingXs)
                .transition(.identity)
                .animation(.easeInOut, value: isEditing)

            if isEditing {
                Button(action: {
                    self.isEditing = false
                    self.text = ""
                    resignFirstResponder()
                }) {
                    Text(L10n.Call.Participants.cancelSearch)
                        .foregroundColor(Color(colors.accentPrimary))
                }
                .frame(height: 20)
                .padding(.trailing, layout.spacingXs)
                .transition(.move(edge: .trailing))
                .animation(.easeInOut)
            }
        }
        .padding(.vertical, layout.spacingXs)
        .onReceive(keyboardWillChangePublisher) { shown in
            if shown {
                self.isEditing = true
            }
            if !shown && isEditing {
                self.isEditing = false
            }
        }
    }
}
