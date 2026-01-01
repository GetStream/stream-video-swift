//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import StreamVideo
import StreamVideoSwiftUI
import StreamVideoUIKit
import SwiftUI
import UIKit

final class HomeViewController: UIViewController {

    @Injected(\.streamVideo) var streamVideo
    @Injected(\.callKitAdapter) var callKitAdapter

    lazy var callViewController = CallViewController()
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
        title = "Call Details"
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
        view.backgroundColor = UIColor.white

        // Present incoming call UI when the app is in the foreground.
        listenToIncomingCalls()

        // Handle CallKit VoIP notifications.
        callKitAdapter.registerForIncomingCalls()
        callKitAdapter.iconTemplateImageData = UIImage(named: "logo")?.pngData()

        streamVideo
            .state
            .$activeCall
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.callViewController.viewModel.setActiveCall($0)
            }
            .store(in: &cancellables)

        navigationItem.leftBarButtonItem = .init(
            title: "Logout",
            primaryAction: .init { [weak self] _ in self?.didTapLogout() }
        )
    }

    // MARK: - Private Helpers

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
        textField.resignFirstResponder()
        let next = CallViewController(viewModel: callViewController.viewModel)
        next.startCall(
            callType: "default",
            callId: text,
            members: selectedParticipants.map { Member(user: $0) }
        )
        CallViewHelper.shared.add(callView: next.view)
    }

    private func didTapLogout() {
        let alertController = UIAlertController(
            title: "Sign out",
            message: "Are you sure you want to sign out?",
            preferredStyle: .alert
        )

        alertController.addAction(.init(title: "Sign out", style: .destructive, handler: { _ in
            Task { await AppState.shared.logout() }
        }))

        alertController.addAction(.init(title: "Cancel", style: .cancel))

        present(alertController, animated: true)
    }

    private func listenToIncomingCalls() {
        callViewController
            .viewModel
            .$callingState
            .removeDuplicates()
            .sink { [weak self] newState in
                log.debug("[UIKit]Received callingState \(newState)")
                switch newState {
                case .incoming:
                    self?.presentCallContainer()
                case .inCall:
                    self?.presentCallContainer()
                default:
                    log.debug("[UIKit]Unhandled callingState \(newState)")
                }
            }
            .store(in: &cancellables)
    }

    private func presentCallContainer() {
        guard self == navigationController?.topViewController else {
            log.warning("[UIKit]Cannot present callView!.")
            return
        }
        CallViewHelper.shared.removeCallView()
        CallViewHelper.shared.add(callView: callViewController.view)
    }
}

extension HomeViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        participants.count
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
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

    func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
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
