//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

public struct OutgoingCallView<CallControls: View, CallTopView: View, Factory: ViewFactory>: View {

    @Injected(\.streamVideo) var streamVideo
    
    @Injected(\.colors) var colors
    @Injected(\.fonts) var fonts
    @Injected(\.images) var images
    @Injected(\.utils) var utils
    
    var viewFactory: Factory
    var outgoingCallMembers: [Member]
    var callTopView: CallTopView
    var callControls: CallControls
    
    public init(
        viewFactory: Factory = DefaultViewFactory.shared,
        outgoingCallMembers: [Member],
        callTopView: CallTopView,
        callControls: CallControls
    ) {
        self.viewFactory = viewFactory
        self.outgoingCallMembers = outgoingCallMembers
        self.callTopView = callTopView
        self.callControls = callControls
    }
    
    public var body: some View {
        CallConnectingView(
            viewFactory: viewFactory,
            outgoingCallMembers: outgoingCallMembers,
            title: L10n.Call.Outgoing.title,
            callControls: callControls,
            callTopView: callTopView
        )
        .onAppear {
            utils.callSoundsPlayer.playOutgoingCallSound()
        }
        .onDisappear {
            utils.callSoundsPlayer.stopOngoingSound()
        }
    }
}

struct OutgoingCallBackground: View {
    
    @Injected(\.streamVideo) var streamVideo
    
    var outgoingCallMembers: [Member]
    
    var body: some View {
        ZStack {
            if outgoingCallMembers.count == 1 {
                CallBackground(imageURL: outgoingCallMembers.first?.user.imageURL)
            } else {
                FallbackBackground()
            }
        }
    }
}

var isSimulator: Bool {
    #if targetEnvironment(simulator)
    return true
    #else
    return false
    #endif
}
