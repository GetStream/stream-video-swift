//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct DemoManualQualitySelectionButtonView: View {

    enum ManualQuality: Hashable {
        case auto
        case fourK
        case fullHD
        case HD
        case SD
        case dataSaver
        case disabled

        var policy: IncomingVideoQualitySettings {
            switch self {
            case .auto:
                return .none
            case .fourK:
                return .manual(group: .all, targetSize: .init(width: 3840, height: 2160))
            case .fullHD:
                return .manual(group: .all, targetSize: .init(width: 1920, height: 1080))
            case .HD:
                return .manual(group: .all, targetSize: .init(width: 1280, height: 720))
            case .SD:
                return .manual(group: .all, targetSize: .init(width: 640, height: 480))
            case .dataSaver:
                return .manual(group: .all, targetSize: .init(width: 256, height: 144))
            case .disabled:
                return .disabled(group: .all)
            }
        }
    }

    @State private var isActive: Bool = false

    private var dismissMoreMenu: () -> Void

    var call: Call?

    init(
        call: Call?,
        _ dismissMoreMenu: @escaping () -> Void
    ) {
        self.call = call
        self.dismissMoreMenu = dismissMoreMenu
    }

    var body: some View {
        Menu {
            buttonView(for: .auto)
            buttonView(for: .fourK)
            buttonView(for: .fullHD)
            buttonView(for: .HD)
            buttonView(for: .SD)
            buttonView(for: .dataSaver)
            buttonView(for: .disabled)
        } label: {
            DemoMoreControlListButtonView(
                action: { isActive.toggle() },
                label: "Manual quality"
            ) {
                Image(
                    systemName: "square.resize"
                )
            }
        }
    }

    @MainActor
    @ViewBuilder
    private func buttonView(
        for manualQuality: ManualQuality
    ) -> some View {
        let title: String = {
            switch manualQuality {
            case .auto:
                return "Auto quality"
            case .fourK:
                return "4K 2160p"
            case .fullHD:
                return "Full HD 1080p"
            case .HD:
                return "HD 720p"
            case .SD:
                return "SD 480p"
            case .dataSaver:
                return "Data saver 144p"
            case .disabled:
                return "Disable video"
            }
        }()
        Button {
            execute(manualQuality)
        } label: {
            Label {
                Text(title)
            } icon: {
                if manualQuality.policy == call?.state.incomingVideoQualitySettings {
                    Image(systemName: "checkmark")
                }
            }
        }
    }

    private func execute(
        _ manualQuality: ManualQuality
    ) {
        Task { @MainActor in
            await call?.setIncomingVideoQualitySettings(manualQuality.policy)
        }
        dismissMoreMenu()
    }
}
