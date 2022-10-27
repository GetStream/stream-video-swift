//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Combine
import UIKit
import StreamVideo
import StreamVideoUIKit
import StreamVideoSwiftUI
import SwiftUI

class HomeViewController: UIViewController {
    
    @Injected(\.streamVideo) var streamVideo
    
    let callViewModel = CallViewModel()
    let reuseIdentifier = "ParticipantCell"
    let startButton = UIButton(type: .system)
    var textField = UITextField()
    var participantsTableView: UITableView!
    var text: String = ""
    
    private var cancellables = Set<AnyCancellable>()
    
    lazy var participants: [UserInfo] = {
        var participants = UserCredentials.builtInUsers.map { $0.userInfo }
        participants.removeAll { userInfo in
            userInfo.id == streamVideo.userInfo.id
        }
        return participants
    }()
    
    var selectedParticipants = [UserInfo]() {
        didSet {
            participantsTableView.reloadData()
        }
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Call Details"
        let stackView = UIStackView(arrangedSubviews: [
            createParticipantsTitle(),
            createParticipantsView(),
            createInputField(),
            createStartButton()
        ])
        stackView.spacing = 24
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .fillProportionally
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
        ])
        self.view.backgroundColor = UIColor.white
        listenToIncomingCalls()
    }
    
    private func createParticipantsView() -> UITableView {
        participantsTableView = UITableView()
        participantsTableView.delegate = self
        participantsTableView.dataSource = self
        participantsTableView.register(
            UITableViewCell.self,
            forCellReuseIdentifier: reuseIdentifier
        )
        participantsTableView.translatesAutoresizingMaskIntoConstraints = false
        participantsTableView.heightAnchor.constraint(equalToConstant: CGFloat(participants.count * 44)).isActive = true
        participantsTableView.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.size.width).isActive = true
        return participantsTableView
    }
    
    private func createParticipantsTitle() -> UILabel {
        let title = UILabel()
        title.text = "Select participants"
        title.font = .preferredFont(forTextStyle: .title3)
        return title
    }
    
    private func createInputField() -> UITextField {
        textField.placeholder = "Insert a call id"
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        return textField
    }
    
    private func createStartButton() -> UIButton {
        startButton.translatesAutoresizingMaskIntoConstraints = false
        startButton.setTitle("Start Call", for: .normal)
        startButton.addTarget(self, action: #selector(didTapStartButton), for: .touchUpInside)
        startButton.isEnabled = false
        return startButton
    }
    
    @objc private func textFieldDidChange() {
        text = textField.text ?? ""
        startButton.isEnabled = !text.isEmpty
    }
    
    @objc private func didTapStartButton() {
        let next = CallViewController.make(with: callViewModel)
        next.modalPresentationStyle = .fullScreen
        next.startCall(callId: text, participants: selectedParticipants)
        self.navigationController?.present(next, animated: true)
    }
    
    private func listenToIncomingCalls() {
        callViewModel.$callingState.sink { newState in
            if case .incoming(_) = newState {
                let next = CallViewController.make(with: self.callViewModel)
                next.modalPresentationStyle = .fullScreen
                self.navigationController?.present(next, animated: true)
            } else if newState == .idle {
                self.navigationController?.presentedViewController?.dismiss(animated: true)
            }
        }
        .store(in: &cancellables)
    }
    
}

extension HomeViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        participants.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: reuseIdentifier)
        }
        let participant = participants[indexPath.row]
        var text = participant.name
        if selectedParticipants.contains(participant) {
            text += " ✅"
        }
        cell?.textLabel?.text = text
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let participant = participants[indexPath.row]
        if selectedParticipants.contains(participant) {
            selectedParticipants.removeAll { userInfo in
                participant.id == userInfo.id
            }
        } else {
            selectedParticipants.append(participant)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
