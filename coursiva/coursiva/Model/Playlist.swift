//
//  Playlist.swift
//  coursiva
//
//  Created by Z1 on 21.06.2025.
//

import Foundation

//MARK: - Response Body for fetchCourseDetails()
struct Playlist: Identifiable, Codable {
    let id: UUID
    let playlistID: String
    let title: String
    let playlistURL: URL
    let playlistThumbnail: URL?
    let userID: Int

    enum CodingKeys: String, CodingKey {
        case id = "uuid_playlist"
        case playlistID = "playlist_id"
        case title
        case playlistURL = "playlist_url"
        case playlistThumbnail = "playlist_thumbnail"
        case userID = "user"
    }
}

//MARK: - createCourse() Response Body
struct CreateCourseResponse: Codable {
    let type: String
    let video: MyVideoResponse?
    let playlist: MyCoursesResponse?
    let user: Int?
}


//MARK: - fetchMyCourses() Response Body
struct MyCoursesWrapper: Codable {
    let playlists: [MyCoursesResponse]
    let single_videos: [MyVideoResponse]
}

struct MyCoursesResponse: Identifiable, Codable {
    let id: UUID
    let title: String
    let playlistThumbnail: URL?
    let videos: [MyVideoResponse]

    enum CodingKeys: String, CodingKey {
        case id = "uuid_playlist"
        case title
        case playlistThumbnail = "playlist_thumbnail"
        case videos
    }
}

struct MyVideoResponse: Identifiable, Codable {
    let id: UUID
    let title: String
    let thumbnail: URL
    let durationSec: Int

    enum CodingKeys: String, CodingKey {
        case id = "uuid_video"
        case title
        case thumbnail
        case durationSec = "duration_sec"
    }
}

