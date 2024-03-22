//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamVideo
import StreamVideoSwiftUI
import SwiftUI
import UIKit

class LoginViewController: UIViewController {

    var onUserSelected: ((UserCredentials) -> Void)?
        
    override func viewDidLoad() {
        super.viewDidLoad()
        let loginView = LoginView { [weak self] credentials in
            self?.onUserSelected?(credentials)
        }
        let loginVC = UIHostingController(rootView: loginView)
        if let loginVCView = loginVC.view {
            view.embed(loginVCView.withoutAutoresizingMaskConstraints)
        }
    }
}
