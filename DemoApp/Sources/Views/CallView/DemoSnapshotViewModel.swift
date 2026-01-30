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
            .receive(on: DispatchQueue.main)
            .compactMap { $0.custom["snapshot"]?.stringValue }
            .compactMap { Data(base64Encoded: $0) }
            .removeDuplicates()
            .log(.debug) { "Snapshot received with data:\($0)" }
            .compactMap { UIImage(data: $0) }
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

struct DemoSnapshotContainerViewModifier: ViewModifier {
    private let viewModel: DemoSnapshotViewModel

    @State private var toast: Toast?

    init(_ callViewModel: CallViewModel) {
        self.viewModel = .init(callViewModel)
    }

    func body(content: Content) -> some View {
        content
            .onReceive(viewModel.$toast.debounce(for: 0.5, scheduler: DispatchQueue.main)) { toast = $0 }
            .toastView(toast: $toast)
    }
}
