//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftUI
import StreamVideo
import StreamVideoSwiftUI

struct ThermalStateViewModifier: ViewModifier {

    @StateObject private var thermalStateObserver: ThermalStateObserver = .shared
    @State private var toast: Binding<Toast?> = .constant(nil)

    func body(content: Content) -> some View {
        content
            .toastView(toast: toast)
            .onReceive(thermalStateObserver.$state) { state in
                switch state {
                case .nominal:
                    toast = .constant(nil)
                case .fair:
                    toast = .constant(nil)
                case .serious:
                    toast = .constant(
                        .init(
                            style: .warning,
                            message: "Device temperature is high.",
                            placement: .top,
                            duration: 5
                        ))
                case .critical:
                    toast = .constant(
                        .init(
                            style: .error,
                            message: "Device temperature is critical.",
                            placement: .top,
                            duration: 5
                        ))
                @unknown default:
                    toast = .constant(nil)
                }
            }
    }
}
