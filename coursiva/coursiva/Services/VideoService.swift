//
//  Untitled.swift
//  coursiva
//
//  Created by Z1 on 07.07.2025.
//

import Foundation

struct VideoService {
    static func fetchVideoDetails(uuid: String) async throws -> Video {
        let jwt = try await APIClient.shared.getJWTToken()
        return try await APIClient.shared.cachedRequest(
            endpoint: .videoDetails(uuid: uuid),
            method: .get,
            token: jwt
        )
    }

    static func fetchLightweightVideos(for playlistUUID: UUID) async throws -> VideoList {
        let jwt = try await APIClient.shared.getJWTToken()
        let response: VideoList = try await APIClient.shared.request(
            endpoint: .courseVideos(uuid: playlistUUID.uuidString.lowercased()),
            method: .get,
            token: jwt
        )

        return response
    }

    static func deleteSingleVideo(uuid: UUID) async throws {
        let jwt = try await APIClient.shared.getJWTToken()
        APIClient.shared.invalidateCache(for: Endpoint.myCourses())
        let _: EmptyResponse = try await APIClient.shared.request(
            endpoint: .deleteSingleVideo(uuid: uuid.uuidString.lowercased()),
            method: .delete,
            token: jwt
        )
    }
}
