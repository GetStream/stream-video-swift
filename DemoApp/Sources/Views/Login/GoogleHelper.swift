//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
@preconcurrency import GoogleSignIn
import GoogleSignInSwift
import StreamVideo

@MainActor
enum GoogleHelper {
    
    static func signIn() async throws -> UserCredentials {
        guard let rootViewController = UIApplication.shared.windows.first?.rootViewController else {
            throw ClientError.Unexpected("No view controller available")
        }
        
        let config = GIDConfiguration(clientID: AppEnvironment.googleClientId)
        return try await withCheckedThrowingContinuation { continuation in
            GIDSignIn.sharedInstance.signIn(with: config, presenting: rootViewController) { user, error in
                guard let userProfile = user?.profile else {
                    let error = ClientError.Unexpected("Error loading user profile")
                    continuation.resume(throwing: error)
                    return
                }
                
                GIDSignIn.sharedInstance.addScopes(["https://www.googleapis.com/auth/directory.readonly"], presenting: rootViewController) { result, error in
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
    
    static func loadUsers() async throws -> [StreamEmployee] {
        guard let currentUser = GIDSignIn.sharedInstance.currentUser else {
            throw ClientError.InvalidToken()
        }
        let urlString = ("https://people.googleapis.com/v1/people:listDirectoryPeople?access_token=\(currentUser.authentication.accessToken)&readMask=emailAddresses,names,photos&sources=DIRECTORY_SOURCE_TYPE_DOMAIN_PROFILE&pageSize=1000")
        
        guard let url = URL(string: urlString) else { throw ClientError.InvalidURL() }
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let json = try JSONSerialization.jsonObject(
            with: data,
            options:[]
        ) as? [String : AnyObject], let people = json["people"] as? [[String: Any]] else {
            throw ClientError.NetworkError()
        }
        
        var result = [StreamEmployee]()
        
        let favoriteUserIds = AppState.shared.unsecureRepository.userFavorites()
        
        for person in people {
            if let emails = person["emailAddresses"] as? [[String: Any]],
                let email = emails.first?["value"] as? String {
                let id = email.replacingOccurrences(of: ".", with: "_")
                let photo = ((person["photos"] as? [[String: Any]])?.first as? [String: Any])?["url"] as? String ?? ""
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
                    imageURL: URL(string: photo)
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
        let token = try await TokenProvider.fetchToken(for: id)
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
