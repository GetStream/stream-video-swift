//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import GoogleSignIn
import GoogleSignInSwift
import StreamVideo

@MainActor
enum GoogleHelper {
    
    private static let baseURL = "https://people.googleapis.com/v1/people:listDirectoryPeople"
    private static let readMask = "readMask=emailAddresses,names,photos"
    private static let sources = "sources=DIRECTORY_SOURCE_TYPE_DOMAIN_PROFILE"
    private static let pageSize = "pageSize=1000"
    private static let directoryScope = "https://www.googleapis.com/auth/directory.readonly"
    
    static func signIn() async throws -> UserCredentials {
        guard
            let rootViewController = UIApplication.shared.windows.first?.rootViewController,
            let clientId: String = AppEnvironment.value(for: .googleClientId)
        else {
            throw ClientError.Unexpected("No view controller available")
        }
        
        let config = GIDConfiguration(clientID: clientId)
        return try await withCheckedThrowingContinuation { continuation in
            GIDSignIn.sharedInstance.signIn(with: config, presenting: rootViewController) { user, error in
                guard let userProfile = user?.profile else {
                    let error = ClientError.Unexpected("Error loading user profile")
                    continuation.resume(throwing: error)
                    return
                }
                
                GIDSignIn.sharedInstance.addScopes(
                    [directoryScope],
                    presenting: rootViewController
                ) { _, error in
                    // According to docs error code - 8 means that the user has
                    // already added the scopes, so it's safe to continue with
                    // sign in.
                    // https://developers.google.com/identity/sign-in/ios/reference/Enums/GIDSignInErrorCode#declaration_5
                    if let error = error as? NSError, error.code != -8 {
                        continuation.resume(throwing: error)
                        return
                    } else {
                        Task {
                            do {
                                let credentials = try await userCredentials(for: userProfile)
                                continuation.resume(returning: credentials)
                            } catch {
                                continuation.resume(throwing: error)
                            }
                        }
                    }
                }
            }
        }
    }

    private static func signIn(addScopes: Bool) {}

    static func loadUsers() async throws -> [StreamEmployee] {
        guard let currentUser = GIDSignIn.sharedInstance.currentUser else {
            throw ClientError.InvalidToken()
        }
        let token = currentUser.authentication.accessToken
        let urlString = ("\(baseURL)?access_token=\(token)&\(readMask)&\(sources)&\(pageSize)")
        
        guard let url = URL(string: urlString) else { throw ClientError.InvalidURL() }
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let json = try JSONSerialization.jsonObject(
            with: data,
            options: []
        ) as? [String: AnyObject], let people = json["people"] as? [[String: Any]] else {
            throw ClientError.NetworkError()
        }
        
        var result = [StreamEmployee]()
        
        let favoriteUserIds = AppState.shared.unsecureRepository.userFavorites()
        
        for person in people {
            if let emails = person["emailAddresses"] as? [[String: Any]],
               let email = emails.first?["value"] as? String {
                let id = email.replacingOccurrences(of: ".", with: "_")
                let firstPhoto = (person["photos"] as? [[String: Any]])?.first as? [String: Any]
                let photoUrl = firstPhoto?["url"] as? String ?? ""
                let name = email
                    .components(separatedBy: "@")
                    .first?
                    .components(separatedBy: ".")
                    .first?
                    .capitalized ?? email
                let employee = StreamEmployee(
                    email: email,
                    id: id,
                    name: name,
                    isFavorite: favoriteUserIds.contains(id),
                    imageURL: URL(string: photoUrl)
                )
                result.append(employee)
            }
        }
        return result
    }
    
    private static func userCredentials(for profile: GIDProfileData) async throws -> UserCredentials {
        let id = profile.email.replacingOccurrences(of: ".", with: "_")
        let userInfo = User(
            id: id,
            name: profile.name,
            imageURL: profile.imageURL(withDimension: 80),
            customData: [:]
        )
        let token = try await AuthenticationProvider.fetchToken(for: id)
        let credentials = UserCredentials(
            userInfo: userInfo,
            token: token
        )
        return credentials
    }
}

struct StreamEmployee: Identifiable, Equatable {
    let email: String
    let id: String
    let name: String
    var isFavorite: Bool
    let imageURL: URL?
}
