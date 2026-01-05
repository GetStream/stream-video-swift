//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

@MainActor
final class DemoSnapshotViewModel: ObservableObject {

    private let viewModel: CallViewModel
    private var cancellable: AnyCancellable?

    @Published var toast: Toast?

    init(_ viewModel: CallViewModel) {
        self.viewModel = viewModel
        subscribeForSnapshotEvents()
    }

    private func subscribeForSnapshotEvents() {
        cancellable?.cancel()
        cancellable = nil

        guard let call = viewModel.call else {
            return
        }

        cancellable = call
            .eventPublisher(for: CustomVideoEvent.self)
            .compactMap {
                guard
                    let imageBase64Data = $0.custom["snapshot"]?.stringValue,
                    let imageData = Data(base64Encoded: imageBase64Data),
                    let image = UIImage(data: imageData)
                else {
                    return nil
                }
                return image
            }
            .map {
                Toast(
                    style: .custom(
                        baseStyle: .success,
                        icon: AnyView(
                            Image(uiImage: $0)
                                .resizable()
                                .frame(maxWidth: 30, maxHeight: 30)
                                .aspectRatio(contentMode: .fit)
                                .clipShape(Circle())
                        )
                    ),
                    message: "Snapshot captured!"
                )
            }
            .assign(to: \.toast, on: self)
    }
}
