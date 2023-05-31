//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

/// View controller reprensetable which wraps up the activity view controller.
public struct ShareActivityView: UIViewControllerRepresentable {

    public var activityItems: [Any]
    public var applicationActivities: [UIActivity]? = nil

    public func makeUIViewController(
        context: UIViewControllerRepresentableContext<ShareActivityView>
    ) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        controller.popoverPresentationController?.sourceView = UIApplication.shared.windows.first?.rootViewController?.view

        return controller
    }

    public func updateUIViewController(
        _ uiViewController: UIActivityViewController,
        context: UIViewControllerRepresentableContext<ShareActivityView>
    ) { /* Not needed. */ }
}
