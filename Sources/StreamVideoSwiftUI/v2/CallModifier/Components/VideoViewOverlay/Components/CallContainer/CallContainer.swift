//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

public struct CallContainer<Factory: ViewFactory>: View {
    private var viewFactory: Factory
    private var viewModel: CallViewModel

    public init(
        viewFactory: Factory = DefaultViewFactory.shared,
        viewModel: CallViewModel
    ) {
        self.viewFactory = viewFactory
        self.viewModel = viewModel
    }
    
    public var body: some View {
        contentView
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .toastView(on: viewModel)
    }

    @ViewBuilder
    private var contentView: some View {
        if #available(iOS 14.0, *) {
            ContentView(
                viewFactory: viewFactory,
                callViewModel: viewModel,
                viewModel: .init(viewModel)
            )
            .id(viewModel.call?.cId)
        } else {
            ContentView_iOS13(
                viewFactory: viewFactory,
                callViewModel: viewModel,
                viewModel: .init(viewModel)
            )
            .id(viewModel.call?.cId)
        }
    }
}

extension CallContainer {
    private final class ViewModel: ObservableObject, @unchecked Sendable {
        @Injected(\.utils) private var utils

        private let cid: String?
        @Published private(set) var callingState: CallingState {
            didSet { didUpdate(callingState) }
        }

        @Published private(set) var participantsCount: Int
        @Published private(set) var isMinimized: Bool

        private let disposableBag = DisposableBag()

        static func == (
            lhs: CallContainer<Factory>.ViewModel,
            rhs: CallContainer<Factory>.ViewModel
        ) -> Bool {
            lhs.cid == rhs.cid
                && lhs.callingState == rhs.callingState
                && lhs.participantsCount == rhs.participantsCount
                && lhs.isMinimized == rhs.isMinimized
        }

        @MainActor
        init(
            _ viewModel: CallViewModel
        ) {
            cid = viewModel.call?.cId
            callingState = viewModel.callingState
            participantsCount = viewModel.callParticipants.count
            isMinimized = viewModel.isMinimized

            viewModel
                .$callParticipants
                .map(\.count)
                .removeDuplicates()
                .assign(to: \.participantsCount, onWeak: self)
                .store(in: disposableBag)

            viewModel
                .$isMinimized
                .removeDuplicates()
                .assign(to: \.isMinimized, onWeak: self)
                .store(in: disposableBag)

            viewModel
                .$callingState
                .removeDuplicates()
                .assign(to: \.callingState, onWeak: self)
                .store(in: disposableBag)
        }

        private func didUpdate(_ callingState: CallingState) {
            guard callingState == .idle || callingState == .inCall else {
                return
            }
            utils.callSoundsPlayer.stopOngoingSound()
        }
    }

    @available(iOS 14.0, *)
    private struct ContentView: View {
        var viewFactory: Factory
        var callViewModel: CallViewModel
        @StateObject var viewModel: ViewModel

        var body: some View {
            Group {
                switch viewModel.callingState {
                case .idle:
                    EmptyView()
                case let .lobby(lobbyInfo):
                    viewFactory.makeLobbyView(
                        viewModel: callViewModel,
                        lobbyInfo: lobbyInfo,
                        callSettings: .init(
                            get: { callViewModel.callSettings },
                            set: { callViewModel.callSettings = $0 }
                        )
                    )
                case let .incoming(incomingCall):
                    viewFactory.makeIncomingCallView(
                        viewModel: callViewModel,
                        callInfo: incomingCall
                    )
                case .outgoing:
                    viewFactory.makeOutgoingCallView(viewModel: callViewModel)
                case .joining:
                    viewFactory.makeJoiningCallView(viewModel: callViewModel)
                case .inCall:
                    if viewModel.participantsCount > 1 {
                        if viewModel.isMinimized {
                            viewFactory.makeMinimizedCallView(viewModel: callViewModel)
                        } else {
                            viewFactory.makeCallView(viewModel: callViewModel)
                        }
                    } else {
                        viewFactory.makeWaitingLocalUserView(viewModel: callViewModel)
                    }
                case .reconnecting:
                    viewFactory.makeReconnectionView(viewModel: callViewModel)
                }
            }
        }
    }

    @available(iOS, introduced: 13, obsoleted: 14)
    private struct ContentView_iOS13: View {
        var viewFactory: Factory
        var callViewModel: CallViewModel
        @BackportStateObject var viewModel: ViewModel

        var body: some View {
            switch viewModel.callingState {
            case .idle:
                EmptyView()
            case let .lobby(lobbyInfo):
                viewFactory.makeLobbyView(
                    viewModel: callViewModel,
                    lobbyInfo: lobbyInfo,
                    callSettings: .init(
                        get: { callViewModel.callSettings },
                        set: { callViewModel.callSettings = $0 }
                    )
                )
            case let .incoming(incomingCall):
                viewFactory.makeIncomingCallView(
                    viewModel: callViewModel,
                    callInfo: incomingCall
                )
            case .outgoing:
                viewFactory.makeOutgoingCallView(viewModel: callViewModel)
            case .joining:
                viewFactory.makeJoiningCallView(viewModel: callViewModel)
            case .inCall:
                if viewModel.participantsCount > 1 {
                    if viewModel.isMinimized {
                        viewFactory.makeMinimizedCallView(viewModel: callViewModel)
                    } else {
                        viewFactory.makeCallView(viewModel: callViewModel)
                    }
                } else {
                    viewFactory.makeWaitingLocalUserView(viewModel: callViewModel)
                }
            case .reconnecting:
                viewFactory.makeReconnectionView(viewModel: callViewModel)
            }
        }
    }
}
