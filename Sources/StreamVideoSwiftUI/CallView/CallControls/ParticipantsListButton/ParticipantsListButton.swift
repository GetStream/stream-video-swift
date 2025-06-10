//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import SwiftUI

/// A button that can be used to present toggle the Participants List's presentation. Additionally, it will
/// display a badge with the number of the total participants in the call.
public struct ParticipantsListButton: View, Equatable {

    var count: Int
    var size: CGFloat
    var isActive: Binding<Bool>
    var actionHandler: () -> Void

    public init(
        viewModel: CallViewModel,
        size: CGFloat = 44
    ) {
        self.init(
            count: viewModel.call?.state.participants.endIndex ?? 0,
            size: size,
            isActive: .init(get: { viewModel.participantsShown }, set: { viewModel.participantsShown = $0 }),
            actionHandler: { [weak viewModel] in viewModel?.participantsShown = true }
        )
    }

    public init(
        count: Int,
        size: CGFloat = 44,
        isActive: Binding<Bool>,
        actionHandler: @escaping () -> Void
    ) {
        self.count = count
        self.size = size
        self.isActive = isActive
        self.actionHandler = actionHandler
    }

    nonisolated public static func == (
        lhs: ParticipantsListButton,
        rhs: ParticipantsListButton
    ) -> Bool {
        lhs.count == rhs.count
            && lhs.size == rhs.size
            && lhs.isActive.wrappedValue == rhs.isActive.wrappedValue
    }

    public var body: some View {
        StatelessParticipantsListButton(
            count: count,
            size: size,
            isActive: isActive,
            actionHandler: actionHandler
        )
        .equatable()
    }
}
