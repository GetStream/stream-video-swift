//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftUI
import StreamVideo
import StreamVideoSwiftUI

struct ThermalStateViewModifier: ViewModifier {

    @Injected(\.thermalStateObserver) var thermalStateObserver
    @State private var toast: Toast? = nil

    func body(content: Content) -> some View {
        content
            .toastView(toast: $toast)
            .onReceive(thermalStateObserver.statePublisher) { state in
                switch state {
                case .nominal:
                    toast = nil
                case .fair:
                    toast = nil
                case .serious:
                    toast = .init(
                        style: .warning,
                        message: "Device temperature is high.",
                        placement: .top,
                        duration: 5
                    )
                case .critical:
                    toast = .init(
                            style: .error,
                            message: "Device temperature is critical.",
                            placement: .top,
                            duration: 5
                        )
                @unknown default:
                    toast = nil
                }
            }
    }
}
