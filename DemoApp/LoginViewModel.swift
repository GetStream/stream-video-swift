//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import SwiftUI
import StreamVideo

@MainActor
class LoginViewModel: ObservableObject {
        
    @Published var loading = false
    
    @Published var userCredentials = UserCredentials.builtInUsers
    
    func login(user: UserCredentials, completion: (UserCredentials) -> ()) {
        AppState.shared.userState = .loggedIn
        // Perform login
        completion(user)
    }
    
}

struct UserCredentials: Identifiable {
    var id: String {
        userInfo.id
    }
    let userInfo: UserInfo
    let token: Token
}

extension UserCredentials {
    
    static func builtInUsersByID(id: String) -> UserCredentials? {
        builtInUsers.filter { $0.id == id }.first
    }
    
    static var builtInUsers: [UserCredentials] = [
        (
            "luke_skywalker",
            "Luke Skywalker",
            "https://vignette.wikia.nocookie.net/starwars/images/2/20/LukeTLJ.jpg",
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoibHVrZV9za3l3YWxrZXIifQ.Ql0LVcZcu4BBi1YuAR_Tjz0aiWJWuzjL-QAPOFsp-d4"
        ),
        (
            "leia_organa",
            "Leia Organa",
            "https://vignette.wikia.nocookie.net/starwars/images/f/fc/Leia_Organa_TLJ.png",
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoibGVpYV9vcmdhbmEifQ.4wZ4_pz5s20IOO1GF6fQ8tQcSdi8_uV5InF0PSREpZ0"
        ),
        (
            "han_solo",
            "Han Solo",
            "https://vignette.wikia.nocookie.net/starwars/images/e/e2/TFAHanSolo.png",
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiaGFuX3NvbG8ifQ.r83FFE9oQoxLgjVoO6-Ky5A2opA0nLvTQqr4PzWCDf8"
        ),
        (
            "lando_calrissian",
            "Lando Calrissian",
            "https://vignette.wikia.nocookie.net/starwars/images/8/8f/Lando_ROTJ.png",
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoibGFuZG9fY2Fscmlzc2lhbiJ9.lhD1e5H5sUNIgcEAj-9htv84Re7ebztoEy9E9gFs1SI"
        ),
        (
            "chewbacca",
            "Chewbacca",
            "https://vignette.wikia.nocookie.net/starwars/images/4/48/Chewbacca_TLJ.png",
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiY2hld2JhY2NhIn0.c4CX0gByW-ZmWApLhgFOfnyXDlZov2mFJkM6HqE-iSM"
        ),
        (
            "c-3po",
            "C-3PO",
            "https://vignette.wikia.nocookie.net/starwars/images/3/3f/C-3PO_TLJ_Card_Trader_Award_Card.png",
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiYy0zcG8ifQ._Q2k7Fig-R79IntBmmkJAj_qkXIxltU7Rsnme8UranQ"
        ),
        (
            "r2-d2",
            "R2-D2",
            "https://vignette.wikia.nocookie.net/starwars/images/e/eb/ArtooTFA2-Fathead.png",
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoicjItZDIifQ.bePaiFHh4lDR16pD-zXE4aQAUyUu96U3Re0g54sGSW4"
        ),
        (
            "anakin_skywalker",
            "Anakin Skywalker",
            "https://vignette.wikia.nocookie.net/starwars/images/6/6f/Anakin_Skywalker_RotS.png",
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiYW5ha2luX3NreXdhbGtlciJ9.TSRZ8iil6VnEwYqGfo3LQ-9H-vOTaBCPpMxGetQ37Pc"
        ),
        (
            "obi-wan_kenobi",
            "Obi-Wan Kenobi",
            "https://vignette.wikia.nocookie.net/starwars/images/4/4e/ObiWanHS-SWE.jpg",
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoib2JpLXdhbl9rZW5vYmkifQ.tLwVX0T5O4vuo09qoMH_YzfgBMEygMtQ54VFpGIdz2M"
        ),
        (
            "padme_amidala",
            "Padmé Amidala",
            "https://vignette.wikia.nocookie.net/starwars/images/b/b2/Padmegreenscrshot.jpg",
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoicGFkbWVfYW1pZGFsYSJ9.yW7OOk0y6YmtPinO8EtJyfhwyEWjYKfyg2Zqa1JulD8"
        ),
        (
            "qui-gon_jinn",
            "Qui-Gon Jinn",
            "https://vignette.wikia.nocookie.net/starwars/images/f/f6/Qui-Gon_Jinn_Headshot_TPM.jpg",
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoicXVpLWdvbl9qaW5uIn0.bltxgWckVVN6XOdPizgJOozOVPxPhBj_f9bye7NALWk"
        ),
        (
            "mace_windu",
            "Mace Windu",
            "https://vignette.wikia.nocookie.net/starwars/images/5/58/Mace_ROTS.png",
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoibWFjZV93aW5kdSJ9.h1Z8Ooy7SIabphTbRmwM2nltSud1NEd9PDBsJ1b4oRg"
        ),
        (
            "jar_jar_binks",
            "Jar Jar Binks",
            "https://vignette.wikia.nocookie.net/starwars/images/d/d2/Jar_Jar_aotc.jpg",
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiamFyX2phcl9iaW5rcyJ9.XBwL4j5ijeIyF9C-Hk1RkYgVQVdRUBy0oKqXJinfrlI"
        ),
        (
            "darth_maul",
            "Darth Maul",
            "https://vignette.wikia.nocookie.net/starwars/images/5/50/Darth_Maul_profile.png",
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiZGFydGhfbWF1bCJ9.hfhccZ2vGRaMwVkgxWOv4GhA5ayYR6Of4spP6VMFG4s"
        ),
        (
            "count_dooku",
            "Count Dooku",
            "https://vignette.wikia.nocookie.net/starwars/images/b/b8/Dooku_Headshot.jpg",
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiY291bnRfZG9va3UifQ.LFEQeMh26fSkEz83q2rNcIvS_GZKuarKyEvLzP1LDnY"
        ),
        (
            "general_grievous",
            "General Grievous",
            "https://vignette.wikia.nocookie.net/starwars/images/d/de/Grievoushead.jpg",
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiZ2VuZXJhbF9ncmlldm91cyJ9.bRZV0C7A-m4J-IORbpPc5cF2GMhzs3k9JfSVdivTtAw"
        )
        
    ].map {
        UserCredentials(
            userInfo: UserInfo(
                id: $0.0,
                name: $0.1,
                imageURL: URL(string: $0.2)!,
                extraData: [:]
            ),
            token: try! Token(rawValue: $0.3)
        )
    }
}
