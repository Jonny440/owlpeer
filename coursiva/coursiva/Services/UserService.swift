import Foundation

struct ProfileUpdateRequest: Codable {
    let first_name: String
    let last_name: String
}

struct UserService {
    /// Fetches the current user's profile.
    static func fetchUser() async throws -> User {
        let jwt = try await APIClient.shared.getJWTToken()
        return try await APIClient.shared.cachedRequest(
            endpoint: .getProfile(),
            method: .get,
            token: jwt
        )
    }

    /// Updates the user's profile with the given first and last name.
    static func updateUser(firstName: String, lastName: String) async throws {
        let jwt = try await APIClient.shared.getJWTToken()
        let requestBody = ProfileUpdateRequest(first_name: firstName, last_name: lastName)
        let body = try JSONEncoder().encode(requestBody)
        _ = try await APIClient.shared.request(
            endpoint: .updateProfile(),
            method: .patch,
            body: body,
            token: jwt
        ) as EmptyResponse? // If you expect a response, change the type
    }
} 
