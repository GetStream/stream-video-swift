//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import UIKit

class CallViewHelper {
    
    static let shared = CallViewHelper()
    
    private var callView: UIView?
    
    private init() {}
    
    func add(callView: UIView) {
        guard self.callView == nil else { return }
        guard let window = UIApplication.shared.windows.first else {
            return
        }
        callView.isOpaque = false
        callView.backgroundColor = UIColor.clear
        self.callView = callView
        window.addSubview(callView)
    }
    
    func removeCallView() {
        callView?.removeFromSuperview()
        callView = nil
    }
}
