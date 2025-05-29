//
//  PublisherSubscriptionView.swift
//  StreamVideo
//
//  Created by Ilias Pavlidakis on 28/5/25.
//

import Combine
import SwiftUI

public struct PublisherSubscriptionView<Value: Equatable, Content: View>: View {

    final class ViewModel: ObservableObject, @unchecked Sendable {

        @Published private(set) var value: Value
        private var cancellable: AnyCancellable?

        init(
            initial: Value,
            publisher: AnyPublisher<Value, Never>?
        ) {
            self.value = initial
            cancellable = publisher?
                .removeDuplicates()
                .receive(on: DispatchQueue.main)
                .assign(to: \.value, onWeak: self)
        }
    }

    @available(iOS 14.0, *)
    struct _PublisherSubscriptionView: View {

        @StateObject private var viewModel: ViewModel
        @ViewBuilder private var contentProvider: (Value) -> Content

        init(
            viewModel: ViewModel,
            @ViewBuilder contentProvider: @escaping (Value) -> Content
        ) {
            _viewModel = .init(wrappedValue: viewModel)
            self.contentProvider = contentProvider
        }

        var body: some View {
            contentProvider(viewModel.value)
        }
    }

    @available(iOS 13.0, *)
    struct _BackportPublisherSubscriptionView: View {

        @BackportStateObject private var viewModel: ViewModel
        @ViewBuilder private var contentProvider: (Value) -> Content

        init(
            viewModel: ViewModel,
            @ViewBuilder contentProvider: @escaping (Value) -> Content
        ) {
            _viewModel = .init(wrappedValue: viewModel)
            self.contentProvider = contentProvider
        }

        var body: some View {
            contentProvider(viewModel.value)
        }
    }

    private let viewModel: ViewModel
    @ViewBuilder private var contentProvider: (Value) -> Content

    public init(
        initial: Value,
        publisher: AnyPublisher<Value, Never>?,
        @ViewBuilder contentProvider: @escaping (Value) -> Content
    ) {
        self.viewModel = .init(initial: initial, publisher: publisher)
        self.contentProvider = contentProvider
    }

    public var body: some View {
        if #available(iOS 14.0, *) {
            _PublisherSubscriptionView(
                viewModel: viewModel,
                contentProvider: contentProvider
            )
        } else {
            _BackportPublisherSubscriptionView(
                viewModel: viewModel,
                contentProvider: contentProvider
            )
        }
    }
}
