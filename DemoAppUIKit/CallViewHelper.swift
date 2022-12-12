//
//  CallViewHelper.swift
//  DemoAppUIKit
//
//  Created by Martin Mitrevski on 12.12.22.
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
