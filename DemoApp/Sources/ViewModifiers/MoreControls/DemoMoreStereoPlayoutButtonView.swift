//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct DemoMoreStereoPlayoutButtonView: View {

    @Injected(\.audioStore) private var audioStore
    @State private var isEnforcingExternalDevices: Bool = false {
        didSet {
            Task { await call?.updateStereoPlayoutEnforcementOnExternalDevices(isEnforcingExternalDevices) }
        }
    }

    @State private var isActive: Bool = false
    @State private var isAvailable: Bool = false

    var call: Call?

    init(call: Call?) {
        self.call = call
    }

    var body: some View {
        HStack {
            stereoPlayoutExternalDevicesEnforcementButtonView
            stereoPlayoutButtonView
        }
    }

    @ViewBuilder
    private var stereoPlayoutExternalDevicesEnforcementButtonView: some View {
        DemoMoreControlListButtonView(
            action: { isEnforcingExternalDevices.toggle() },
            label: "Stereo on External"
        ) { Text(isEnforcingExternalDevices ? "🟢" : "🟠") }
    }

    @ViewBuilder
    private var stereoPlayoutButtonView: some View {
        DemoMoreControlListButtonView(
            action: {
                // TODO: ------
//                audioStore.setStereoPlayoutPreference(!isActive)
            },
            label: isActive ? "Disable stereo Playout" : "Enable stereo playout",
            disabled: !isAvailable
        ) {
            Image(
                systemName: isActive ? "dot.radiowaves.left.and.right" : "dot.radiowaves.right"
            )
        }
        .onReceive(audioStore.publisher(\.stereo.playoutAvailable).receive(on: DispatchQueue.main)) { isAvailable = $0 }
    }
}
