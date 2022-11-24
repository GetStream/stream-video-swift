//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Combine
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI
import UIKit

open class CallViewController: UIViewController {
    
    var viewModel: CallViewModel!
    
    private var cancellables = Set<AnyCancellable>()
    
    public static func make(with viewModel: CallViewModel? = nil) -> CallViewController {
        let controller = CallViewController()
        controller.viewModel = viewModel ?? CallViewModel()
        return controller
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        view = PassthroughView(frame: view.frame)
        let videoView = VideoView(viewFactory: DefaultViewFactory.shared, viewModel: viewModel)
        let uiKitView = VideoViewContainer(view: videoView, frame: view.frame)
        view.embed(uiKitView)
    }
    
    public func startCall(callId: String, participants: [User]) {
        viewModel.startCall(callId: callId, participants: participants)
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

final class VideoViewContainer: UIView {
    
    init(view: VideoView<DefaultViewFactory>, frame: CGRect) {
        let uiView = UIHostingController(rootView: view).view!
        uiView.backgroundColor = .clear
        
        super.init(frame: .zero)
        
        addSubview(uiView)
        uiView.frame = frame
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
