//
// Copyright © 2023 Stream.io Inc. All rights reserved.
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
    
    lazy var participants: [User] = {
        var participants = User.builtIn
        participants.removeAll { userInfo in
            userInfo.id == streamVideo.user.id
        }
        return participants
    }()
    
    var selectedParticipants = [User]() {
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
        participantsTableView.heightAnchor.constraint(equalToConstant: CGFloat(participants.count * 36)).isActive = true
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
        next.startCall(
            callType: "default",
            callId: text,
            members: selectedParticipants.map { MemberRequest(userId: $0.id) }
        )
        CallViewHelper.shared.add(callView: next.view)
    }
    
    private func listenToIncomingCalls() {
        callViewModel.$callingState.sink { [weak self] newState in
            guard let self = self else { return }
            if case .incoming(_) = newState, self == self.navigationController?.topViewController {
                let next = CallViewController.make(with: self.callViewModel)
                CallViewHelper.shared.add(callView: next.view)
            } else if newState == .idle {
                CallViewHelper.shared.removeCallView()
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
