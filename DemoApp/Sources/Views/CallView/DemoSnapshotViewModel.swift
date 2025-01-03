//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

@MainActor
final class DemoSnapshotViewModel: ObservableObject {

    private let viewModel: CallViewModel
    private var snapshotEventsTask: Task<Void, Never>?

    @Published var toast: Toast?

    init(_ viewModel: CallViewModel) {
        self.viewModel = viewModel
        subscribeForSnapshotEvents()
    }

    private func subscribeForSnapshotEvents() {
        guard let call = viewModel.call else {
            snapshotEventsTask?.cancel()
            snapshotEventsTask = nil
            return
        }

        snapshotEventsTask = Task {
            for await event in call.subscribe(for: CustomVideoEvent.self) {
                guard
                    let imageBase64Data = event.custom["snapshot"]?.stringValue,
                    let imageData = Data(base64Encoded: imageBase64Data),
                    let image = UIImage(data: imageData)
                else {
                    return
                }

                toast = .init(
                    style: .custom(
                        baseStyle: .success,
                        icon: AnyView(
                            Image(uiImage: image)
                                .resizable()
                                .frame(maxWidth: 30, maxHeight: 30)
                                .aspectRatio(contentMode: .fit)
                                .clipShape(Circle())
                        )
                    ),
                    message: "Snapshot captured!"
                )
            }
        }
    }
}
