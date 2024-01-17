//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftUI
import StreamVideo

struct ParticipantsListViewModifier<EmbeddedView: View>: ViewModifier {

    @Injected(\.fonts) var fonts
    @Injected(\.colors) var colors

    var isPresented: Binding<Bool>
    var embeddedView: () -> EmbeddedView

    func body(content: Content) -> some View {
        content
            .halfSheet(isPresented: isPresented) { embeddedView() }
    }
}

extension View {

    @ViewBuilder
    public func presentParticipantListView(
        isPresented: Binding<Bool>,
        @ViewBuilder embeddedView: @escaping () -> some View
    ) -> some View {
        modifier(
            ParticipantsListViewModifier(
                isPresented: isPresented,
                embeddedView: embeddedView
            )
        )
    }
}
