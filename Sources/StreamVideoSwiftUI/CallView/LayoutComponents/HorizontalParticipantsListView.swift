//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import StreamVideo
import SwiftUI

/// `HorizontalParticipantsListView` represents a horizontally scrollable view of participant thumbnails.
/// This component lays out participant thumbnails in a bar at the bottom of the associated view.
public struct HorizontalParticipantsListView<Factory: ViewFactory>: View {

    // MARK: - Properties

    /// Factory for creating views.
    var viewFactory: Factory

    /// Frame in which the component will be laid out.
    var frame: CGRect

    /// Information about the call (if available).
    var call: Call?

    /// The space between items
    var innerItemSpace: CGFloat

    /// Flag to determine if all participant information should be shown.
    var showAllInfo: Bool

    /// Private computed properties for laying out the view.
    var barFrame: CGRect

    var itemFrame: CGRect

    /// List of participants to display.
    var participants: [CallParticipant]

    // MARK: - Initialization

    /// Creates a new instance of `HorizontalParticipantsListView`.
    public init(
        viewFactory: Factory = DefaultViewFactory.shared,
        participants: [CallParticipant],
        frame: CGRect,
        call: Call?,
        innerItemSpace: CGFloat = 8,
        showAllInfo: Bool = false
    ) {
        self.viewFactory = viewFactory
        self.frame = frame
        self.call = call
        self.innerItemSpace = innerItemSpace
        self.showAllInfo = showAllInfo
        self.participants = participants

        // Calculate the frame for the bar at the bottom.
        let barFrame = CGRect(
            origin: .init(x: frame.origin.x, y: frame.maxY - frame.height),
            size: CGSize(width: frame.size.width, height: frame.height)
        )
        self.barFrame = barFrame

        let aspectRatioWidth = min(barFrame.width, barFrame.height * 16 / 9)
        itemFrame = .init(
            origin: .zero,
            size: .init(
                width: aspectRatioWidth - innerItemSpace / 2,
                height: barFrame.height
            )
        )
    }

    // MARK: - View Body

    /// Defines the structure and layout of the view.
    public var body: some View {
        // Scroll view to accommodate multiple participant thumbnails.
        ScrollView(.horizontal, showsIndicators: false) {
            // Container for horizontal alignment.
            HorizontalContainer {
                // Loop through each participant and display their thumbnail.
                ForEach(participants) { participant in
                    viewFactory.makeVideoParticipantView(
                        participant: participant,
                        id: participant.id,
                        availableFrame: itemFrame,
                        contentMode: .scaleAspectFill,
                        customData: [:],
                        call: call
                    )
                    .modifier(
                        viewFactory.makeVideoCallParticipantModifier(
                            participant: participant,
                            call: call,
                            availableFrame: itemFrame,
                            ratio: itemFrame.width / itemFrame.height,
                            showAllInfo: showAllInfo
                        )
                    )
                    // Observe visibility changes.
                    .visibilityObservation(
                        in: barFrame
                    ) { isVisible in
                        Task {
                            await call?.changeTrackVisibility(
                                for: participant,
                                isVisible: isVisible
                            )
                        }
                    }
                    .cornerRadius(8)
                    .accessibility(identifier: "horizontalParticipantsListParticipant")
                }
            }
            .frame(height: barFrame.height)
            .cornerRadius(8)
        }
        .accessibility(identifier: "horizontalParticipantsList")
    }
}
