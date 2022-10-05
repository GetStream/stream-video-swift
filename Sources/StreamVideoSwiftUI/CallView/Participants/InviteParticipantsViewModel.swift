//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamVideo

@MainActor
class InviteParticipantsViewModel: ObservableObject {
    
    @Published var searchText = ""
    
    @Published var selectedUsers = [UserInfo]()
    @Published var allUsers = [UserInfo]()
    
    var filteredUsers: [UserInfo] {
        if searchText.isEmpty {
            return allUsers
        } else {
            return allUsers.filter { user in
                let name = (user.name).lowercased()
                return name.contains(searchText.lowercased())
            }
        }
    }
        
    init(currentParticipants: [CallParticipant]) {
        let participantIds = currentParticipants.map(\.id)
        // TODO: temp implementation while backend is ready.
        allUsers = Self.builtInUsers.filter { !participantIds.contains($0.id) }
    }
    
    func userTapped(_ user: UserInfo) {
        if selectedUsers.contains(user) {
            selectedUsers.removeAll { current in
                user.id == current.id
            }
        } else {
            selectedUsers.append(user)
        }
    }
    
    func isSelected(user: UserInfo) -> Bool {
        selectedUsers.contains(user)
    }
    
    func onlineInfo(for user: UserInfo) -> String {
        // TODO: provide implementation
        "Offline"
    }
    
    // TODO: remove when backend ready.
    static var builtInUsers: [UserInfo] = [
        (
            "luke_skywalker",
            "Luke Skywalker",
            "https://vignette.wikia.nocookie.net/starwars/images/2/20/LukeTLJ.jpg"
        ),
        (
            "leia_organa",
            "Leia Organa",
            "https://vignette.wikia.nocookie.net/starwars/images/f/fc/Leia_Organa_TLJ.png"
        ),
        (
            "han_solo",
            "Han Solo",
            "https://vignette.wikia.nocookie.net/starwars/images/e/e2/TFAHanSolo.png"
        ),
        (
            "lando_calrissian",
            "Lando Calrissian",
            "https://vignette.wikia.nocookie.net/starwars/images/8/8f/Lando_ROTJ.png"
        ),
        (
            "chewbacca",
            "Chewbacca",
            "https://vignette.wikia.nocookie.net/starwars/images/4/48/Chewbacca_TLJ.png"
        ),
        (
            "c-3po",
            "C-3PO",
            "https://vignette.wikia.nocookie.net/starwars/images/3/3f/C-3PO_TLJ_Card_Trader_Award_Card.png"
        ),
        (
            "r2-d2",
            "R2-D2",
            "https://vignette.wikia.nocookie.net/starwars/images/e/eb/ArtooTFA2-Fathead.png"
        ),
        (
            "anakin_skywalker",
            "Anakin Skywalker",
            "https://vignette.wikia.nocookie.net/starwars/images/6/6f/Anakin_Skywalker_RotS.png"
        ),
        (
            "obi-wan_kenobi",
            "Obi-Wan Kenobi",
            "https://vignette.wikia.nocookie.net/starwars/images/4/4e/ObiWanHS-SWE.jpg"
        ),
        (
            "padme_amidala",
            "Padmé Amidala",
            "https://vignette.wikia.nocookie.net/starwars/images/b/b2/Padmegreenscrshot.jpg"
        ),
        (
            "qui-gon_jinn",
            "Qui-Gon Jinn",
            "https://vignette.wikia.nocookie.net/starwars/images/f/f6/Qui-Gon_Jinn_Headshot_TPM.jpg"
        ),
        (
            "mace_windu",
            "Mace Windu",
            "https://vignette.wikia.nocookie.net/starwars/images/5/58/Mace_ROTS.png"
        ),
        (
            "jar_jar_binks",
            "Jar Jar Binks",
            "https://vignette.wikia.nocookie.net/starwars/images/d/d2/Jar_Jar_aotc.jpg"
        ),
        (
            "darth_maul",
            "Darth Maul",
            "https://vignette.wikia.nocookie.net/starwars/images/5/50/Darth_Maul_profile.png"
        ),
        (
            "count_dooku",
            "Count Dooku",
            "https://vignette.wikia.nocookie.net/starwars/images/b/b8/Dooku_Headshot.jpg"
        ),
        (
            "general_grievous",
            "General Grievous",
            "https://vignette.wikia.nocookie.net/starwars/images/d/de/Grievoushead.jpg"
        )
        
    ].map {
        UserInfo(id: $0.0, name: $0.1, imageURL: URL(string: $0.2))
    }
}
