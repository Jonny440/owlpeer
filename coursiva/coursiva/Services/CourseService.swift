//
//  CoursesService.swift
//  coursiva
//
//  Created by Z1 on 07.07.2025.
//

import Foundation
import Get

struct CourseService {
    static func fetchMyCourses(forceRefresh: Bool) async throws -> MyCoursesWrapper {
        let jwt = try await APIClient.shared.getJWTToken()
        return try await APIClient.shared.cachedRequest(endpoint: .myCourses(), method: .get, token: jwt, forceRefresh: forceRefresh)
    }

    static func createCourse(from url: String) async throws -> CreateCourseResponse {
        let jwt = try await APIClient.shared.getJWTToken()
        let body = try JSONEncoder().encode(["url": url])
        return try await APIClient.shared.request(endpoint: .createCourse(), method: .post, body: body, token: jwt)
    }

    static func fetchCourseDetails(for uuid: UUID) async throws -> Playlist {
        let jwt = try await APIClient.shared.getJWTToken()
        return try await APIClient.shared.request(endpoint: .courseDetails(uuid: uuid), method: .get, token: jwt)
    }

    static func deleteCourse(uuid: UUID) async throws {
        let jwt = try await APIClient.shared.getJWTToken()
        APIClient.shared.invalidateCache(for: Endpoint.myCourses())
        let _: EmptyResponse = try await APIClient.shared.request(endpoint: .deleteCourse(uuid: uuid.uuidString.lowercased()), method: .delete, token: jwt)
    }
}

