//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import SwiftUI

private struct CallEndedViewModifier<Subview: View>: ViewModifier {

    private final class CallEndedViewModifierState: ObservableObject {
        @Published var call: Call?
        @Published var isPresentingSubview: Bool = false

        init() {}
    }

    private var notificationCenter: NotificationCenter
    private var subviewProvider: (Call?) -> Subview

    @StateObject private var state: CallEndedViewModifierState = .init()

    init(
        notificationCenter: NotificationCenter,
        @ViewBuilder subviewProvider: @escaping (Call?) -> Subview
    ) {
        self.notificationCenter = notificationCenter
        self.subviewProvider = subviewProvider
    }

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $state.isPresentingSubview) {
                subviewProvider(state.call)
            }
            .onReceive(
                notificationCenter.publisher(for: .init(CallNotification.callEnded))
            ) { notification in
                guard let call = notification.object as? Call else {
                    log.warning("Received CallNotification.callEnded but the object isn't a call.")
                    state.isPresentingSubview = false
                    return
                }

                guard state.call?.cId != call.cId else {
                    return
                }

                log.debug("Received CallNotification.callEnded for call:\(call.cId)")
                state.call = call
                state.isPresentingSubview = true
            }
    }
}

extension View {

    @ViewBuilder
    public func onCallEnded(
        notificationCenter: NotificationCenter = .default,
        @ViewBuilder _ content: @escaping (Call?) -> some View
    ) -> some View {
        modifier(
            CallEndedViewModifier(
                notificationCenter: notificationCenter,
                subviewProvider: content
            )
        )
    }
}
