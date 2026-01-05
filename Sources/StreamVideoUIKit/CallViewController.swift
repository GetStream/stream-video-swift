//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI
import UIKit

@MainActor
open class CallViewController: UIViewController {
    
    public private(set) var viewModel: CallViewModel
    
    private var cancellables = Set<AnyCancellable>()
    
    public static func make(with viewModel: CallViewModel? = nil) -> CallViewController {
        CallViewController(viewModel: viewModel ?? .init())
    }

    public convenience init() {
        self.init(viewModel: .init())
    }

    public init(viewModel: CallViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override open func viewDidLoad() {
        super.viewDidLoad()
        view = PassthroughView(frame: view.frame)
        view.backgroundColor = .clear
        setupVideoView()
    }
    
    open func setupVideoView() {
        let videoView = makeVideoView(with: DefaultViewFactory.shared)
        videoView.translatesAutoresizingMaskIntoConstraints = false
        view.embed(videoView)
    }
    
    open func makeVideoView<Factory: ViewFactory>(with viewFactory: Factory) -> UIView {
        if #available(iOS 14.0, *) {
            let videoView = CallContainer(viewFactory: viewFactory, viewModel: viewModel)
            return CallViewContainer(view: videoView, frame: view.frame)
        } else {
            let videoView = CallContainer_iOS13(viewFactory: viewFactory, viewModel: viewModel)
            return CallViewContainer(view: videoView, frame: view.frame)
        }
    }
    
    public func startCall(
        callType: String,
        callId: String,
        members: [Member],
        team: String? = nil,
        ring: Bool = false,
        video: Bool? = nil
    ) {
        viewModel.startCall(
            callType: callType,
            callId: callId,
            members: members,
            team: team,
            ring: ring,
            video: video
        )
        listenToCallStateChanges()
    }
    
    private func listenToCallStateChanges() {
        viewModel.$callingState.sink { newState in
            if newState == .idle {
                self.dismiss(animated: true)
            }
        }
        .store(in: &cancellables)
    }
}

class PassthroughView: UIView {
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard let slideView = subviews.first else {
            return false
        }
        
        return slideView.hitTest(convert(point, to: slideView), with: event) != nil
    }
}

final class CallViewContainer: UIView {
    
    @available(iOS 14.0, *)
    init<Factory: ViewFactory>(view: CallContainer<Factory>, frame: CGRect) {
        let uiView = UIHostingController(rootView: view).view!
        uiView.backgroundColor = .clear
        
        super.init(frame: .zero)

        uiView.translatesAutoresizingMaskIntoConstraints = false
        embed(uiView)
    }
    
    @available(iOS, introduced: 13, obsoleted: 14)
    init<Factory: ViewFactory>(view: CallContainer_iOS13<Factory>, frame: CGRect) {
        let uiView = UIHostingController(rootView: view).view!
        uiView.backgroundColor = .clear
        
        super.init(frame: .zero)
        
        uiView.translatesAutoresizingMaskIntoConstraints = false
        embed(uiView)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Passing the touch to the below layer if its not hitting one of its subviews
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard let swiftUISubviews = subviews.first?.subviews else {
            return false
        }
        if swiftUISubviews.contains(where: {
            $0.alpha > 0.01 &&
                !$0.isHidden &&
                $0.isUserInteractionEnabled &&
                $0.point(inside: self.convert(point, to: $0), with: event)
        }) {
            return true
        }
        return false
    }
}
