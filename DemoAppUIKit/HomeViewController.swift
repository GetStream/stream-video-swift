//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamVideo
import StreamVideoUIKit
import StreamVideoSwiftUI
import SwiftUI

class HomeViewController: UIViewController {
    
    let startButton = UIButton(type: .system)
    var textField: UITextField!
    var text: String = ""
        
    override func viewDidLoad() {
        super.viewDidLoad()
        let stackView = UIStackView(arrangedSubviews: [
            createInputField(), createStartButton()
        ])
        stackView.spacing = 32
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .fillProportionally
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        self.view.backgroundColor = UIColor.white
    }
    
    func createInputField() -> UITextField {
        textField = UITextField()
        textField.placeholder = "Insert a call id"
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        return textField
    }
    
    func createStartButton() -> UIButton {
        startButton.translatesAutoresizingMaskIntoConstraints = false
        startButton.setTitle("Start Call", for: .normal)
        startButton.addTarget(self, action: #selector(didTapStartButton), for: .touchUpInside)
        startButton.isEnabled = false
        return startButton
    }
    
    @objc func textFieldDidChange() {
        text = textField.text ?? ""
        startButton.isEnabled = !text.isEmpty
    }
    
    @objc func didTapStartButton() {
        let next = CallViewController.make()
        next.modalPresentationStyle = .fullScreen
        next.startCall(callId: text, participants: [])
        self.navigationController?.present(next, animated: true)
    }
}
