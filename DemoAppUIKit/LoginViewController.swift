//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

class LoginViewController: UIViewController {

    var onUserSelected: ((UserCredentials) -> ())?

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let loginView = LoginView { [weak self] credentials in
            self?.onUserSelected?(credentials)
        }
        let loginVC = UIHostingController(rootView: loginView)
        if let loginVCView = loginVC.view {
            view.embed(loginVCView.withoutAutoresizingMaskConstraints)
        }
    }
}
